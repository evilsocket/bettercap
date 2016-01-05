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
class None < Base
  def initialize
    Logger.warn 'Spoofing disabled.'
  end

  def start; end

  def stop; end
end
end
end
