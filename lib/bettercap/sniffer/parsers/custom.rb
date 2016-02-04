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
# Parser used when the "--custom-parser EXPRESSION" command line
# argument is specified.
class Custom < Base
  # Initialize the parser given the +filter+ Regexp object.
  def initialize( filter )
    @filters = [ filter ]
    @name    = 'DATA'
  end
end
end
end
