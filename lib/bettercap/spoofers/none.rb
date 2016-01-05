=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require 'bettercap/spoofers/base'
require 'bettercap/logger'

module BetterCap
module Spoofers
# Dummy class used to disable spoofing.
class None < Base
  # Initialize the non-spoofing class.
  def initialize
    Logger.warn 'Spoofing disabled.'
  end

  # This does nothing.
  def start; end

  # This does nothing.
  def stop; end
end
end
end
