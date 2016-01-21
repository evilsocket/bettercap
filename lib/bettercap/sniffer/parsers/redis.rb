=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require 'bettercap/sniffer/parsers/base'

module BetterCap
module Parsers
# Redis authentication parser.
class Redis < Base
  def initialize
    @filters = [ /AUTH\s+.+/ ]
    @name = 'REDIS'
  end
end
end
end
