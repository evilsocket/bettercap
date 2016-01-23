=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

require 'rubydns'

module BetterCap
module Proxy
module SSLStrip

# TODO: Class to handle DNS resolving for HSTS bypass.
class Resolver
  # Use upstream DNS for name resolution.
  UPSTREAM = RubyDNS::Resolver.new([[:udp, "8.8.8.8", 53], [:tcp, "8.8.8.8", 53]])

  # Create an instance of this object making the DNS server
  # bind to +address+:+port+.
  def initialize( address = "0.0.0.0", port = 5300 )
    @ifaces = [
      [:udp, address, port],
      [:tcp, address, port]
    ]
  end

  def start
    Thread.new {
      RubyDNS::run_server(:listen => @ifaces) do
        #match(/google\.com/, Resolv::DNS::Resource::IN::A) do |transaction|
        #  transaction.respond!("10.0.0.80")
        #end

        # Default DNS handler
        otherwise do |transaction|
          transaction.passthrough!(UPSTREAM)
        end
      end
    }
  end
end

end
end
end
