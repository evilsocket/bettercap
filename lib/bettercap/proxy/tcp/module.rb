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

# Base class for transparent TCP proxy modules.
class Module
  # This callback is called when the target is sending data to the upstream server.
  # +event+ is an instance of the BetterCap::Proxy::TCP::Event class.
  def on_data( event ); end
  # This callback is called when the upstream server is sending data to the target.
  # +event+ is an instance of the BetterCap::Proxy::TCP::Event class.
  def on_response( event ); end
  # This callback is called when the connection is terminated.
  # +event+ is an instance of the BetterCap::Proxy::TCP::Event class.
  def on_finish( event ); end

  # Loaded modules.
  @@loaded = {}

  class << self
    def inherited(subclass)
      name = subclass.name.upcase
      @@loaded[name] = subclass
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

    def on_data( event )
      @@loaded.each do |name,mod|
        mod.on_data( event )
      end
    end

    def on_response( event )
      @@loaded.each do |name,mod|
        mod.on_response( event )
      end
    end

    def on_finish( event )
      @@loaded.each do |name,mod|
        mod.on_finish( event )
      end
    end
  end
end

end
end
end
