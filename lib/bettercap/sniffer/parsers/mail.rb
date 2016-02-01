# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

module BetterCap
module Parsers
# POP/IMAP authentication parser.
class Mail < Base
  def initialize
    @filters = [ /(\d+ )?(auth|authenticate) ([a-z\-_0-9]+)/i ]
    @name = 'MAIL'
  end
end
end
end
