# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

module BetterCap
module Proxy
module HTTP

# Transparent HTTP proxy class.
class Proxy
  # Initialize the transparent proxy, making it listen on +address+:+port+.
  # If +is_https+ is true a HTTPS proxy will be created, otherwise a HTTP one.
  def initialize( address, port, is_https )
    @socket        = nil
    @address       = address
    @port          = port
    @is_https      = is_https
    @type          = is_https ? 'HTTPS' : 'HTTP'
    @upstream_port = is_https ? 443 : 80
    @allow_local   = Context.get.options.proxies.allow_local_connections
    @server        = nil
    @sslserver     = nil
    @main_thread   = nil
    @running       = false
    @local_ips     = []
    @streamer      = Streamer.new( need_sslstrip? )

    begin
      @local_ips = Socket.ip_address_list.collect { |x| x.ip_address }
    rescue
      Logger.warn 'Could not get local ips using Socket module, using Network.get_local_ips method.'

      @local_ips = Network.get_local_ips
    end

    BasicSocket.do_not_reverse_lookup = true

    tmin = System.cpu_count
    tmax = tmin * 16

    @pool = ThreadPool.new( tmin, tmax ) do |client|
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
      @socket = TCPServer.new( @address, @port )

      if @is_https
        @sslserver = SSL::Server.new( @socket )
        @server    = @sslserver.io
      else
        @server    = @socket
      end

      @main_thread = Thread.new &method(:server_thread)
    rescue Errno::EADDRINUSE
      raise BetterCap::Error, "[#{@type} PROXY] It looks like there's another process listening on #{@address}:#{@port}, please chose a different port."
    rescue Exception => e
      Logger.error "Error starting #{@type} proxy: #{e.inspect}"
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

  # Main server thread, will accept incoming connections and push them to
  # the thread pool.
  def server_thread
    Logger.info "[#{@type.green}] Proxy starting on #{@address}:#{@port} ...\n"

    @running = true
    sockets  = [ @server ]

    while @running do
      begin
        IO.select(sockets).first.each do |sock|
          begin
            if io = sock.accept_nonblock
              @pool << io
            end
          rescue SystemCallError
            # nothing
          rescue Errno::ECONNABORTED
            # client closed the socket even before accept
            io.close rescue nil
          end
        end
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
      elsif !@allow_local and is_self_request? request
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

  # Return true if sslstrip is needed for this proxy instance.
  def need_sslstrip?
    ( Context.get.options.proxies.sslstrip and !@is_https )
  end
end

end
end
end
