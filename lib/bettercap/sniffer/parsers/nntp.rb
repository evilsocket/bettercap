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
# NNTP authentication parser.
class Nntp < Base
  def initialize
    @filters = [ /(authinfo|AUTHINFO)\s+(user|USER|pass|PASS)\s+.+/ ]
    @name = 'NNTP'
  end
end
end
end
