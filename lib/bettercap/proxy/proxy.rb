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
  def initialize address, port, &processor
    @socket      = nil
    @address     = address
    @port        = port
    @main_thread = nil
    @running     = false
    @processor   = processor
    @local_ips   = []

    begin
      @local_ips = Socket.ip_address_list.collect { |x| x.ip_address }
    rescue
      Logget.warn 'Could not get local ips using Socket module, using Network.get_local_ips method.'

      @local_ips = Network.get_local_ips
    end
  end

  def start
    begin
      @socket = TCPServer.new( @address, @port )
      @main_thread = Thread.new &method(:server_thread)
    rescue Exception => e
      Logger.error "Error starting proxy: #{e.inspect}"
      @socket.close unless @socket.nil?
    end
  end

  def stop
    begin
      Logger.info 'Stopping proxy ...'

      if @socket and @running
        @running = false
        @socket.close
      end
    rescue
    end
  end

  private

  def server_thread
    Logger.info "Proxy started on #{@address}:#{@port} ...\n"

    @running = true

    begin
      while @running do
        Thread.new @socket.accept, &method(:client_thread)
      end
    rescue Exception => e
      if @running
        Logger.warn "Error while accepting connection: #{e.inspect}"
      end
    ensure
      @socket.close unless @socket.nil?
    end
  end

  def binary_streaming from, to, opts = {}

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
        if not opts[:request].nil? and opts[:request].is_post?
          opts[:request] << buff
        end

        # we've done reading?
        break unless read != total_size
      end
    end
  end

  def html_streaming request, response, from, to
    buff = ""
    loop do
      from.read 1024, buff

      break unless buff.size > 0

      response << buff
    end

    @processor.call( request, response )

    # Response::to_s will patch the headers if needed
    to.write response.to_s
  end

  def log_stream client, request, response
    client_s   = "[#{client}]"
    verb_s     = request.verb
    request_s  = "http://#{request.host}#{request.url}"
    response_s = "( #{response.content_type} )"
    request_s  = request_s.slice(0..50) + "..." unless request_s.length <= 50

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

  def is_self_request? request
    @local_ips.include? IPSocket.getaddress(request.host)
  end

  def rickroll_lamer client
    client.write "HTTP/1.1 302 Found\n"
    client.write "Location: https://www.youtube.com/watch?v=dQw4w9WgXcQ\n\n"
  end

  def client_thread client
    client_port, client_ip = Socket.unpack_sockaddr_in(client.getpeername)
    Logger.debug "New connection from #{client_ip}:#{client_port}"

    server = nil
    request = Request.new

    begin
      # read the first line
      request << client.readline

      loop do
        line = client.readline
        request << line

        if line.chomp == ""
          break
        end
      end

      raise "Couldn't extract host from the request." unless request.host

      # someone is having fun with us =)
      if is_self_request? request

        Logger.warn "#{client_ip} is connecting to us directly."

        rickroll_lamer client

      else

        server = TCPSocket.new( request.host, request.port )

        server.write request.to_s

        # this is probably a POST request, collect incoming data
        if request.content_length > 0
          Logger.debug "Getting #{request.content_length} bytes from client"

          binary_streaming client, server, :request => request
        end

        Logger.debug 'Reading response ...'

        response = Response.new

        # read all response headers
        loop do
          line = server.readline

          response << line

          break unless not response.headers_done
        end

        if response.is_textual?
          log_stream client_ip, request, response

          Logger.debug 'Detected textual response'

          html_streaming request, response, server, client
        else
          Logger.debug "[#{client_ip}] -> #{request.host}#{request.url} [#{response.code}]"

          Logger.debug 'Binary streaming'

          binary_streaming server, client, :response => response
        end

        Logger.debug "#{client_ip}:#{client_port} served."
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
