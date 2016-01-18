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
  end

  # Redirect the +client+ to a funny video.
  def rickroll( client )
    Logger.warn "#{client_ip} is connecting to us directly."

    client.write "HTTP/1.1 302 Found\n"
    client.write "Location: https://www.youtube.com/watch?v=dQw4w9WgXcQ\n\n"
  end

  # Handle the HTTP +request+ from +client+, if +is_https+ is true it will be
  # forwarded as a HTTPS request.
  def handle( request, client, is_https )
    response = Response.new
    client_ip, client_port = get_client_details( is_https, client )

    Logger.debug "Handling #{request.verb} request from #{client_ip}:#{client_port} ..."

    begin
      self.send( "do_#{request.verb}", request, response )

      if response.textual?
        StreamLogger.log_http( is_https, client_ip, request, response )
      else
        Logger.debug "[#{client_ip}] -> #{request.host}#{request.url} [#{response.code}]"
      end

      @processor.call( request, response )

      client.write response.to_s
    rescue NoMethodError
      Logger.warn "Could not handle #{request.verb} request from #{client_ip}:#{client_port} ..."
    end
  end

  private

  def get_client_details( is_https, client )
    unless is_https
      client_port, client_ip = Socket.unpack_sockaddr_in(client.getpeername)
    else
      _, client_port, _, client_ip = client.peeraddr
    end

    [ client_ip, client_port ]
  end

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

  def do_CONNECT(req, res)
    Logger.error "You're using bettercap as a normal HTTP(S) proxy, it wasn't designed to handle CONNECT requests:\n\n#{req.to_s}"
  end

  def do_GET(req, res)
    perform_proxy_request(req, res) do |http, path, header|
      http.get(path, header)
    end
  end

  def do_HEAD(req, res)
    perform_proxy_request(req, res) do |http, path, header|
      http.head(path, header)
    end
  end

  def do_POST(req, res)
    perform_proxy_request(req, res) do |http, path, header|
      http.post(path, req.body || "", header)
    end
  end

end
end
end
