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
  def initialize( address, port, is_https, &processor )
    @socket      = nil
    @address     = address
    @port        = port
    @is_https    = is_https
    @type        = is_https ? 'HTTPS' : 'HTTP'
    @sslserver   = nil
    @sslcontext  = nil
    @main_thread = nil
    @running     = false
    @processor   = processor
    @local_ips   = []

    begin
      @local_ips = Socket.ip_address_list.collect { |x| x.ip_address }
    rescue
      Logger.warn 'Could not get local ips using Socket module, using Network.get_local_ips method.'

      @local_ips = Network.get_local_ips
    end
  end

  def start
    begin
      @socket = TCPServer.new( @address, @port )

      if @is_https
        # We're not acting as a normal HTTPS proxy, thus we're not
        # able to handle CONNECT requests, thus we don't know the
        # hostname the client is going to connect to.
        # We can only use a self signed certificate.
        cert = CertStore.get_selfsigned

        @sslcontext      = OpenSSL::SSL::SSLContext.new
        @sslcontext.cert = cert[:cert]
        @sslcontext.key  = cert[:key]

        @sslserver = OpenSSL::SSL::SSLServer.new( @socket, @sslcontext )
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
      end
    rescue
    end
  end

  private

  def async_accept
    if @is_https
      begin
        Thread.new @sslserver.accept, &method(:client_thread)
      rescue OpenSSL::SSL::SSLError => e
        Logger.warn "Error while accepting #{@type} connection: #{e.inspect}"
      end
    else
      Thread.new @socket.accept, &method(:client_thread)
    end
  end

  def server_thread
    Logger.info "#{@type} Proxy started on #{@address}:#{@port} ...\n"

    @running = true

    begin
      while @running do
        async_accept
      end
    rescue Exception => e
      if @running
        Logger.error "Error while accepting #{@type} connection: #{e.inspect}"
      end
    ensure
      @socket.close unless @socket.nil?
    end
  end

  def binary_streaming( from, to, opts = {} )

    total_size = 0

    # if response|request object is available and a content length as well
    # use it to speed up data streaming with precise data size
    if not opts[:response].nil?
      to.write opts[:response].to_s

      total_size = opts[:response].content_length unless opts[:response].content_length.nil?
    elsif not opts[:request].nil?

      total_size = opts[:request].content_length unless opts[:request].content_length.nil?
    end

    buff = ""
    read = 0

    if total_size
      chunk_size = 1024
    else
      chunk_size = [ 1024, total_size ].min
    end

    if chunk_size > 0
      loop do
        from.read chunk_size, buff

        # nothing more to read?
        break unless buff.size > 0

        to.write buff

        read += buff.size

        # collect into the proper object
        if not opts[:request].nil? and opts[:request].post?
          opts[:request] << buff
        end

        # we've done reading?
        break unless read != total_size
      end
    end
  end

  def html_streaming( request, response, from, to )
    buff = ''
    loop do
      from.read 1024, buff

      break unless buff.size > 0

      response << buff
    end

    @processor.call( request, response )

    # Response::to_s will patch the headers if needed
    to.write response.to_s
  end

  def log_stream( client, request, response )
    client_s   = "[#{client}]"
    verb_s     = request.verb
    request_s  = "#{@is_https ? 'https' : 'http'}://#{request.host}#{request.url}"
    response_s = "( #{response.content_type} )"
    request_s  = request_s.slice(0..50) + '...' unless request_s.length <= 50

    verb_s = verb_s.light_blue

    if response.code[0] == '2'
      response_s += " [#{response.code}]".green
    elsif response.code[0] == '3'
      response_s += " [#{response.code}]".light_black
    elsif response.code[0] == '4'
      response_s += " [#{response.code}]".yellow
    elsif response.code[0] == '5'
      response_s += " [#{response.code}]".red
    else
      response_s += " [#{response.code}]"
    end

    Logger.write "#{client_s} #{verb_s} #{request_s} #{response_s}"
  end

  def is_self_request?(request)
    @local_ips.include? IPSocket.getaddress(request.host)
  end

  def rickroll_lamer(client)
    client.write "HTTP/1.1 302 Found\n"
    client.write "Location: https://www.youtube.com/watch?v=dQw4w9WgXcQ\n\n"
  end

  def create_upstream_connection( request )
    if @is_https
      sock = TCPSocket.new( request.host, request.port )

      ctx = OpenSSL::SSL::SSLContext.new

      # do we need this? :P ctx.set_params(verify_mode: OpenSSL::SSL::VERIFY_PEER)

      socket = OpenSSL::SSL::SSLSocket.new(sock, ctx).tap do |socket|
        socket.sync_close = true
        socket.connect
      end

      socket
    else
      TCPSocket.new( request.host, request.port )
    end
  end

  def get_client_details( client )
    if !@is_https
      client_port, client_ip = Socket.unpack_sockaddr_in(client.getpeername)
    else
      _, client_port, _, client_ip = client.peeraddr
    end

    [ client_ip, client_port ]
  end

  def client_thread( client )
    client_ip, client_port = get_client_details client

    Logger.debug "New #{@type} connection from #{client_ip}:#{client_port}"

    server = nil
    request = Request.new @is_https ? 443 : 80

    Logger.debug 'Created request ...'

    begin
      Logger.debug 'Reading request ...'

      # read the first line
      request << client.readline

      loop do
        line = client.readline
        request << line

        if line.chomp == ''
          break
        end
      end

      raise "Couldn't extract host from the #{@type} request." unless request.host

      # someone is having fun with us =)
      if is_self_request? request

        Logger.warn "#{client_ip} is connecting to us directly."

        rickroll_lamer client

      elsif request.verb == 'CONNECT'

        Logger.error "You're using bettercap as a 'normal' HTTPS proxy, it wasn't designed to handle CONNECT requests."

      else

        Logger.debug 'Creating upstream connection ...'

        server = create_upstream_connection request

        server.write request.to_s

        # this is probably a POST request, collect incoming data
        if request.content_length > 0
          Logger.debug "Getting #{request.content_length} bytes from client"

          binary_streaming client, server, request: request
        end

        Logger.debug 'Reading response ...'

        response = Response.new

        # read all response headers
        loop do
          line = server.readline

          response << line

          break unless not response.headers_done
        end

        if response.textual?
          log_stream client_ip, request, response

          Logger.debug 'Detected textual response'

          html_streaming request, response, server, client
        else
          Logger.debug "[#{client_ip}] -> #{request.host}#{request.url} [#{response.code}]"

          Logger.debug 'Binary streaming'

          binary_streaming server, client, response: response
        end

        Logger.debug "#{@type} client served."
      end

    rescue Exception => e
      if request.host
        Logger.debug "Error while serving #{request.host}#{request.url}: #{e.inspect}"
        Logger.debug e.backtrace
      end
    ensure
      client.close
      server.close unless server.nil?
    end
  end
end


end
