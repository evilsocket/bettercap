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

# Class to handle a list of ( client, url ) objects.
class URLMonitor
  # Create an instance of this object.
  def initialize
    @urls = []
  end

  # Return true if the object (client, url) is found inside this list.
  def secure_link?( client, url )
    @urls.include?([client, url])
  end

  # Add the object (client, url) to this list.
  def add!( client, url )
    unless secure_link?(client, url)
      @urls << [client, url]
    end
  end
end

end
end
end
