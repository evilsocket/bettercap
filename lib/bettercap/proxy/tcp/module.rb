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
module TCP

# Base class for transparent pTCP roxy modules.
class Module
  def on_data( ip, port, data ); end
  def on_response( ip, port, response ); end
  def on_finish( ip, port ); end

  @@loaded = {}

  class << self
    def inherited(subclass)
      name = subclass.name.upcase
      @@loaded[name] = subclass
    end

    # Return a list of available spoofers names.
    def available
      @@loaded.keys
    end

    def load( ctx, opts, file )
      begin
        require file
      rescue LoadError
        raise BetterCap::Error, "Invalid TCP proxy module specified."
      end

      @@loaded.each do |name,mod|
        @@loaded[name] = mod.new
      end
    end

    def on_data( ip, port, data )
      backup = data
      @@loaded.each do |name,mod|
        data = mod.on_data( ip, port, data )
      end
      ( data || backup )
    end

    def on_response( ip, port, data )
      backup = data
      @@loaded.each do |name,mod|
        data = mod.on_response( ip, port, data )
      end
      ( data || backup )
    end

    def on_finish( ip, port )
      @@loaded.each do |name,mod|
        mod.on_finish( ip, port )
      end
    end
  end
end

end
end
end
