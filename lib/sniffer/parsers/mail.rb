=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require_relative 'base'

class MailParser < BaseParser
    def initialize
        @filters = [ /(\d+ )?(auth|authenticate) (login|plain)/i, /(\d+ )?login/i ]
        @name = 'MAIL'
    end
end
