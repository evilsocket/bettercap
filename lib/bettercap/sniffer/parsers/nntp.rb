# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : https://www.evilsocket.net/

NNTP authentication parser:
  Author : Brendan Coles
  Email  : bcoles[at]gmail.com

This project is released under the GPL 3 license.

=end

module BetterCap
module Parsers
# NNTP authentication parser.
class Nntp < Base
  def initialize
    @filters = [ /AUTHINFO\s+(USER|PASS)\s+.+/i ]
    @name = 'NNTP'
  end
end
end
end
