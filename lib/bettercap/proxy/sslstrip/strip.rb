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

class Strip
  def initialize
    @urlmonitor = URLMonitor.new
  end

  def process( client_ip, request, response )
    response.body.scan( /(https:\/\/[^"'\/]+)/i ).uniq.each do |link|
      link = link[0]
      if link.include?('.')
        Logger.info "[#{'sslstrip'.green}] Found HTTPS link '#{link}'"
        @urlmonitor.add!( client_ip, link )
        response.body.gsub!( link, link.gsub( 'https://', 'http://' ) )
      end
    end
  end
end

end
end
end
