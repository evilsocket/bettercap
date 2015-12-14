=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

require 'socket'
require 'uri'

require 'bettercap/logger'
require 'bettercap/network'

module Proxy

class Proxy
  def initialize( address, port, is_https, processor )
    @socket      = nil
    @address     = address
    @port        = port
    @is_https    = is_https
    @type        = is_https ? 'HTTPS' : 'HTTP'
    @sslserver   = nil
    @sslcontext  = nil
    @server      = nil
    @main_thread = nil
    @running     = false
    @streamer    = Streamer.new processor
    @local_ips   = []

    begin
      @local_ips = Socket.ip_address_list.collect { |x| x.ip_address }
    rescue
      Logger.warn 'Could not get local ips using Socket module, using Network.get_local_ips method.'

      @local_ips = Network.get_local_ips
    end

    BasicSocket.do_not_reverse_lookup = true

    @pool = ThreadPool.new( 4, 16 ) do |client|
       client_worker client
    end
  end

  def start
    begin
      @server = @socket = TCPServer.new( @address, @port )

      if @is_https
        cert = Context.get.certificate

        @sslcontext      = OpenSSL::SSL::SSLContext.new
        @sslcontext.cert = cert[:cert]
        @sslcontext.key  = cert[:key]

        @server = @sslserver = OpenSSL::SSL::SSLServer.new( @socket, @sslcontext )
      end

      @main_thread = Thread.new &method(:server_thread)
    rescue Exception => e
      Logger.error "Error starting #{@type} proxy: #{e.inspect}"
      @socket.close unless @socket.nil?
    end
  end

  def stop
    begin
      Logger.info "Stopping #{@type} proxy ..."

      if @socket and @running
        @running = false
        @socket.close
        @pool.shutdown
      end
    rescue
    end
  end

  private

  def server_thread
    Logger.info "#{@type} Proxy started on #{@address}:#{@port} ...\n"

    @running = true

    while @running do
      begin
        @pool << @server.accept
      rescue Exception => e
        Logger.warn("Error while accepting #{@type} connection: #{e.inspect}") \
        unless !@running
      end
    end

    @socket.close unless @socket.nil?
  end

  def is_self_request?(request)
    @local_ips.include? IPSocket.getaddress(request.host)
  end

  def create_upstream_connection( request )
    sock = TCPSocket.new( request.host, request.port )

    if @is_https
      ctx = OpenSSL::SSL::SSLContext.new
      # do we need this? :P ctx.set_params(verify_mode: OpenSSL::SSL::VERIFY_PEER)

      sock = OpenSSL::SSL::SSLSocket.new(sock, ctx).tap do |socket|
        sock.sync_close = true
        sock.connect
      end
    end

    sock
  end

  def get_client_details( client )
    if !@is_https
      client_port, client_ip = Socket.unpack_sockaddr_in(client.getpeername)
    else
      _, client_port, _, client_ip = client.peeraddr
    end

    [ client_ip, client_port ]
  end

  def client_worker( client )
    client_ip, client_port = get_client_details client

    Logger.debug "New #{@type} connection from #{client_ip}:#{client_port}"

    server = nil
    request = Request.new @is_https ? 443 : 80

    begin
      Logger.debug 'Reading request ...'

      request.read client

      # someone is having fun with us =)
      if is_self_request? request

        Logger.warn "#{client_ip} is connecting to us directly."

        @streamer.rickroll client

      elsif request.verb == 'CONNECT'

        Logger.error "You're using bettercap as a normal HTTP(S) proxy, it wasn't designed to handle CONNECT requests:\n\n#{request.to_s}"

      else

        Logger.debug 'Creating upstream connection ...'

        server = create_upstream_connection request

        sreq = request.to_s

        Logger.debug "Sending request:\n#{sreq}"

        server.write sreq

        # this is probably a POST request, collect incoming data
        if request.content_length > 0
          Logger.debug "Getting #{request.content_length} bytes from client"

          @streamer.binary client, server, request: request
        end

        Logger.debug 'Reading response ...'

        response = Response.from_socket server

        if response.textual?
          StreamLogger.log( @is_https, client_ip, request, response )

          Logger.debug 'Detected textual response'

          @streamer.html request, response, server, client
        else
          Logger.debug "[#{client_ip}] -> #{request.host}#{request.url} [#{response.code}]"

          Logger.debug 'Binary streaming'

          @streamer.binary server, client, response: response
        end

        Logger.debug "#{@type} client served."
      end

    rescue Exception => e
      if request.host
        Logger.warn "Error while serving #{request.host}#{request.url}: #{e.inspect}"
        Logger.debug e.backtrace.join("\n")
      end
    end

    client.close
    server.close unless server.nil?
  end
end


end
