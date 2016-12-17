# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : https://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

module BetterCap
module Parsers
# POP/IMAP authentication parser.
class Mail < Base
  def initialize
    @filters = [ /(USER|PASS)\s+.+/ ]
    @name = 'MAIL'
    @port = 110
  end
end
end
end
