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

# Base class for transparent TCP proxy modules, example:
#
#  class SampleModule < BetterCap::Proxy::TCP::Module
#    def on_data( event )
#      event.data = 'aaa'
#    end
#
#    def on_response( event )
#      event.data = 'bbb'
#    end
#  end
class Module < BetterCap::Pluggable
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
    # Called when a class inherits this base class.
    def inherited(subclass)
      name = subclass.name.upcase
      @@loaded[name] = subclass
    end

    # Load +file+ as a proxy module.
    def load( file )
      begin
        require file
      rescue LoadError => e
        raise BetterCap::Error, "Invalid TCP proxy module specified: #{e.message}"
      end

      @@loaded.each do |name,mod|
        @@loaded[name] = mod.new
      end
    end

    # Execute method +even_name+ for each loaded module instance using +event+
    # as its argument.
    def dispatch( event_name, event )
      @@loaded.each do |name,mod|
        mod.send( event_name, event )
      end
    end
  end
end

end
end
end
