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

# Class to handle a list of ( client, url ) objects.
class URLMonitor
  # Create an instance of this object.
  def initialize
    @urls = []
  end

  # Return true if the object (client, url) is found inside this list.
  def was_stripped?( client, url )
    @urls.include?([client, url])
  end

  # Add the object (client, url) to this list.
  def add!( client, url )
    unless was_stripped?(client, url)
      @urls << [client, url]
    end
  end

  # Return a normalized version of +url+.
  def normalize( url )
    url = if url.include?('://') then url else "https://#{url}" end
    url = if url.end_with?('/') then url else "#{url}/" end
    url
  end

  # Downgrade +url+ from HTTPS to HTTP.
  # Will take care of HSTS bypass urls in a near future.
  def downgrade( url )
    url.gsub( 'https://', 'http://' )
  end
end

end
end
end
