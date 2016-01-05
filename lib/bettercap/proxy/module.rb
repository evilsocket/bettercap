=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require 'bettercap/logger'

module BetterCap
module Proxy
# Base class for transparent proxy modules.
class Module
  @@modules = []
  # Return a list of registered modules.
  def self.modules
    @@modules
  end

  # Return true if the module is enabled, otherwise false.
  def enabled?
    true
  end

  # Register available proxy modules into the system.
  def self.register_modules
    Object.constants.each do |klass|
      const = Kernel.const_get(klass)
      if const.respond_to?(:superclass) and const.superclass == self
        Logger.debug "Registering module #{const}"
        @@modules << const.new
      end
    end
  end
end
end
end
