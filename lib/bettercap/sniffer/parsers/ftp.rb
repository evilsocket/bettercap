=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require 'bettercap/sniffer/parsers/base'

class FtpParser < BaseParser
    def initialize
        @filters = [ /(USER|PASS)\s+.+/ ]
        @name = 'FTP'
    end
end
