# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

require 'socket'
require 'uri'

module BetterCap
module Proxy
# Transparent proxy class.
class Proxy
  # Initialize the transparent proxy, making it listen on +address+:+port+ and
  # use the specified +processor+ routine for each request.
  # If +is_https+ is true a HTTPS proxy will be created, otherwise a HTTP one.
  def initialize( address, port, is_https, processor )
    @socket        = nil
    @address       = address
    @port          = port
    @is_https      = is_https
    @type          = is_https ? 'HTTPS' : 'HTTP'
    @upstream_port = is_https ? 443 : 80
    @sslserver     = nil
    @sslcontext    = nil
    @sslauthority  = nil
    @server        = nil
    @main_thread   = nil
    @running       = false
    @streamer      = Streamer.new processor
    @local_ips     = []

    begin
      @local_ips = Socket.ip_address_list.collect { |x| x.ip_address }
    rescue
      Logger.warn 'Could not get local ips using Socket module, using Network.get_local_ips method.'

      @local_ips = Network.get_local_ips
    end

    BasicSocket.do_not_reverse_lookup = true

    @pool = ThreadPool.new( 4, 64 ) do |client|
      begin
       client_worker client
      rescue Exception => e
        Logger.warn "Client worker error: #{e.message}"
        Logger.exception e
      end
    end
  end

  # Start this proxy instance.
  def start
    begin
      @server = @socket = TCPServer.new( @address, @port )

      setup_ssl! if @is_https

      @main_thread = Thread.new &method(:server_thread)
    rescue Exception => e
      Logger.error "Error starting #{@type} proxy: #{e.inspect}"
      @socket.close unless @socket.nil?
    end
  end

  # Stop this proxy instance.
  def stop
    begin
      Logger.info "Stopping #{@type} proxy ..."

      if @socket and @running
        @running = false
        @socket.close
        @pool.shutdown false
      end
    rescue
    end
  end

  private

  # Method used to setup HTTPS related objects.
  def setup_ssl!
    @sslauthority    = Context.get.authority
    @sslcontext      = OpenSSL::SSL::SSLContext.new
    @sslcontext.cert = @sslauthority.certificate
    @sslcontext.key  = @sslauthority.key

    # If the client supports SNI ( https://en.wikipedia.org/wiki/Server_Name_Indication )
    # we'll receive the hostname it wants to connect to in this callback.
    # Use the CA we already have loaded ( or generated ) to sign a new
    # certificate at runtime with the correct 'Common Name' and create a new SSL
    # context with it.
    @sslcontext.servername_cb = proc { |sslsocket, hostname|
      Logger.debug "[#{'SSL'.green}] Server-Name-Indication for '#{hostname}'"

      ctx      = OpenSSL::SSL::SSLContext.new
      ctx.cert = @sslauthority.clone( hostname )
      ctx.key  = @sslauthority.key

      ctx
    }

    @server = @sslserver = OpenSSL::SSL::SSLServer.new( @socket, @sslcontext )
  end

  # Main server thread, will accept incoming connections and push them to
  # the thread pool.
  def server_thread
    Logger.info "[#{@type.green}] Proxy starting on #{@address}:#{@port} ...\n"

    @running = true

    while @running do
      begin
        @pool << @server.accept
      rescue OpenSSL::SSL::SSLError => se
        Logger.debug("Error while accepting #{@type} connection ( #{se.message} ).")
      rescue Exception => e
        Logger.warn("Error while accepting #{@type} connection: #{e.inspect}") if @running
      end
    end

    @socket.close unless @socket.nil?
  end

  # Return true if the +request+ host header contains one of this computer
  # ip addresses.
  def is_self_request?(request)
    begin
      return @local_ips.include? IPSocket.getaddress(request.host)
    rescue; end
    false
  end

  # Handle a new +client+.
  def client_worker( client )
    request = Request.new @upstream_port

    begin
      Logger.debug 'Reading request ...'

      request.read(client)

      Logger.debug 'Request parsed.'

      # stripped request
      if @streamer.was_stripped?( request, client )
        @streamer.handle( request, client )
      # someone is having fun with us =)
      elsif is_self_request? request
        @streamer.rickroll( client )
      # handle request
      else
        @streamer.handle( request, client )
      end

      Logger.debug "#{@type} client served."

    rescue SocketError => se
      Logger.debug "Socket error while serving client: #{se.message}"
      # Logger.exception se
    rescue Errno::EPIPE => ep
      Logger.debug "Connection closed while serving client."
    rescue EOFError => eof
      Logger.debug "EOFError while serving client."
    rescue Exception => e
      Logger.warn "Error while serving client: #{e.message}"
      Logger.exception e
    end

    client.close
  end
end

end
end
