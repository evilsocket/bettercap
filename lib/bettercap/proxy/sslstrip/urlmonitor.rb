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

# https://github.com/moxie0/sslstrip/blob/master/sslstrip/URLMonitor.py
class URLMonitor
  def initialize
    @urls = []
  end

  def secure_link?( client, url )
    @urls.include?([client, url])
  end

  def add!( client, url )
    unless secure_link?(client, url)
      @urls << [client, url]
    end
  end
end

end
end
end
