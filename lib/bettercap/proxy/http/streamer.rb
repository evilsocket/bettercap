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

# Handle data streaming between clients and servers for the BetterCap::Proxy::HTTP::Proxy.
class Streamer
  # Initialize the class.
  def initialize( sslstrip )
    @ctx       = Context.get
    @sslstrip  = SSLStrip::Strip.new( @ctx ) if sslstrip
  end

  # Return true if the +request+ was stripped.
  def was_stripped?(request, client)
    if @sslstrip
      request.client, _ = get_client_details( client )
      return @sslstrip.was_stripped?(request)
    end
    false
  end

  # Redirect the +client+ to a funny video.
  def rickroll( client )
    client_ip, client_port = get_client_details( client )

    Logger.warn "#{client_ip}:#{client_port} is connecting to us directly."

    client.write Response.redirect( "https://www.youtube.com/watch?v=dQw4w9WgXcQ" ).to_s
  end

  # Handle the HTTP +request+ from +client+.
  def handle( request, client, redirects = 0 )
    response = Response.new
    request.client, _ = get_client_details( client )

    Logger.debug "Handling #{request.method} request from #{request.client} ..."

    begin
      r = nil
      if @sslstrip
        r = @sslstrip.preprocess( request )
      end

      if r.nil?
        # call modules on_pre_request
        r = process( request )
        if r.nil?
          self.send( "do_#{request.method}", request, response )
        else
          Logger.info "[#{'PROXY'.green}] Module returned crafted response."
          response = r
        end
      else
        response = r
      end

      if response.textual? or request.method == 'DELETE'
        StreamLogger.log_http( request, response )
      else
        Logger.debug "[#{request.client}] -> #{request.to_url} [#{response.code}]"
      end

      if @sslstrip
        # do we need to retry the request?
        if @sslstrip.process( request, response ) == true
          # https redirect loop?
          if redirects < SSLStrip::Strip::MAX_REDIRECTS
            return self.handle( request, client, redirects + 1 )
          else
            Logger.info "[#{'SSLSTRIP'.red} #{request.client}] Detected HTTPS redirect loop for '#{request.host}'."
          end
        end
      end

      # Strip out a few security headers.
      strip_security( response )

      # call modules on_request
      process( request, response )

      client.write response.to_s
    rescue NoMethodError => e
      Logger.warn "Could not handle #{request.method} request from #{request.client} ..."
      Logger.exception e
    end
  end

  private

  # Run proxy modules.
  def process( request, response = nil )
    # loop each loaded module and execute if enabled
    BetterCap::Proxy::HTTP::Module.modules.each do |mod|
      if mod.enabled?
        # we need to save the original response in case something
        # in the module will go wrong
        original = response

        begin
          if response.nil?
            r = mod.on_pre_request request
            # the handler returned a response, do not execute
            # the request
            response = r unless r.nil?
          else
            mod.on_request request, response
          end
        rescue Exception => e
          Logger.warn "Error with proxy module: #{e.message}"
          Logger.exception e

          response = original
        end
      end
    end
    return response
  end

  # List of security headers to remove/patch from any response.
  # Thanks to Mazin Ahmed ( @mazen160 )
  SECURITY_HEADERS = {
    'X-Frame-Options'                     => nil,
    'X-Content-Type-Options'              => nil,
    'Strict-Transport-Security'           => nil,
    'X-WebKit-CSP'                        => nil,
    'Public-Key-Pins'                     => nil,
    'Public-Key-Pins-Report-Only'         => nil,
    'X-Content-Security-Policy'           => nil,
    'Content-Security-Policy-Report-Only' => nil,
    'Content-Security-Policy'             => nil,
    'X-Download-Options'                  => nil,
    'X-Permitted-Cross-Domain-Policies'   => nil,
    'Allow-Access-From-Same-Origin'       => '*',
    'Access-Control-Allow-Origin'         => '*',
    'Access-Control-Allow-Methods'        => '*',
    'Access-Control-Allow-Headers'        => '*',
    'X-Xss-Protection'                    => '0'
  }.freeze

  # Strip out a few security headers from +response+.
  def strip_security( response )
    SECURITY_HEADERS.each do |name,value|
      response[name] = value
    end
  end

  # Return the +client+ ip address and port.
  def get_client_details( client )
    _, client_port, _, client_ip = client.peeraddr
    [ client_ip, client_port ]
  end

  # Use a Net::HTTP object in order to perform the +req+ BetterCap::Proxy::HTTP::Request
  # object, will return a BetterCap::Proxy::HTTP::Response object instance.
  def perform_proxy_request(req, res)
    path             = req.path
    response         = nil
    http             = Net::HTTP.new( req.host, req.port )
    http.use_ssl     = ( req.port == 443 )
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

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

  # Handle a DELETE request, +req+ is the request object and +res+ the response.
  def do_DELETE(req, res)
    perform_proxy_request(req, res) do |http, path, header|
      http.delete(path, header)
    end
  end

  # Handle a POST request, +req+ is the request object and +res+ the response.
  def do_POST(req, res)
    perform_proxy_request(req, res) do |http, path, header|
      http.post(path, req.body || "", header)
    end
  end

  # Handle a PUT request, +req+ is the request object and +res+ the response.
  def do_PUT(req, res)
    perform_proxy_request(req, res) do |http, path, header|
      http.put(path, req.body || "", header)
    end
  end

end
end
end
end
