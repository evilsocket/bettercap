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
# IRC protocol parser.
class Irc < Base
  def initialize
    @filters = [ /NICK\s+.+/, /NS IDENTIFY\s+.+/, /nickserv :identify\s+.+/ ]
    @name = 'IRC'
  end
end
end
end
