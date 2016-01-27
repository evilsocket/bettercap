# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require 'bettercap/logger'

module BetterCap
module Proxy
# Handle data streaming between clients and servers for the BetterCap::Proxy::Proxy.
class Streamer
  # Initialize the class with the given +processor+ routine.
  def initialize( processor )
    @processor = processor
    @ctx       = Context.get
    @sslstrip  = SSLStrip::Strip.new
  end

  # Redirect the +client+ to a funny video.
  def rickroll( client, is_https )
    client_ip, client_port = get_client_details( is_https, client )

    Logger.warn "#{client_ip}:#{client_port} is connecting to us directly."

    client.write "HTTP/1.1 302 Found\n"
    client.write "Location: https://www.youtube.com/watch?v=dQw4w9WgXcQ\n\n"
  end

  # Handle the HTTP +request+ from +client+.
  def handle( request, client, redirects = 0 )
    response = Response.new
    is_https = request.port == 443
    request.client, request.client_port = get_client_details( is_https, client )

    Logger.debug "Handling #{request.verb} request from #{request.client}:#{request.client_port} ..."

    begin
      r = nil
      if @ctx.options.sslstrip
        r = @sslstrip.preprocess( request )
      end

      if r.nil?
        # call modules on_pre_request
        @processor.call( request, nil )

        self.send( "do_#{request.verb}", request, response )
      else
        response = r
      end

      if response.textual?
        StreamLogger.log_http( request, response )
      else
        Logger.debug "[#{request.client}] -> #{request.host}#{request.url} [#{response.code}]"
      end

      if @ctx.options.sslstrip
        # do we need to retry the request?
        if @sslstrip.process( request, response ) == true
          # https redirect loop?
          if redirects < SSLStrip::Strip::MAX_REDIRECTS
            return self.handle( request, client, redirects + 1 )
          else
            Logger.info "[#{'SSLSTRIP'.yellow} #{request.client}] Detected HTTPS redirect loop for '#{request.host}'."
          end
        end
      end

      # call modules on_request
      @processor.call( request, response )

      client.write response.to_s
    rescue NoMethodError => e
      Logger.warn "Could not handle #{request.verb} request from #{request.client}:#{request.client_port} ..."
      Logger.debug e.inspect
      Logger.debug e.backtrace.join("\n")
    end
  end

  private

  # Return the +client+ ip address and port.
  def get_client_details( is_https, client )
    unless is_https
      client_port, client_ip = Socket.unpack_sockaddr_in(client.getpeername)
    else
      _, client_port, _, client_ip = client.peeraddr
    end

    [ client_ip, client_port ]
  end

  # Use a Net::HTTP object in order to perform the +req+ BetterCap::Proxy::Request
  # object, will return a BetterCap::Proxy::Response object instance.
  def perform_proxy_request(req, res)
    path         = req.url
    response     = nil
    http         = Net::HTTP.new( req.host, req.port )
    http.use_ssl = ( req.port == 443 )

    http.start do
      response = yield( http, path, req.headers )
    end

    res.convert_webrick_response!(response)
  end

  # Handle a CONNECT request, +req+ is the request object and +res+ the response.
  def do_CONNECT(req, res)
    Logger.error "You're using bettercap as a normal HTTP(S) proxy, it wasn't designed to handle CONNECT requests:\n\n#{req.to_s}"
  end

  # Handle a GET request, +req+ is the request object and +res+ the response.
  def do_GET(req, res)
    perform_proxy_request(req, res) do |http, path, header|
      http.get(path, header)
    end
  end

  # Handle a HEAD request, +req+ is the request object and +res+ the response.
  def do_HEAD(req, res)
    perform_proxy_request(req, res) do |http, path, header|
      http.head(path, header)
    end
  end

  # Handle a POST request, +req+ is the request object and +res+ the response.
  def do_POST(req, res)
    perform_proxy_request(req, res) do |http, path, header|
      http.post(path, req.body || "", header)
    end
  end

end
end
end
