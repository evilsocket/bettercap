=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require_relative '../logger'
require 'colorize'

class HttpParser
    def on_packet( pkt )
        if pkt.to_s =~ /(GET|POST)\s+.+HTTP.+/
            Logger.write "[#{pkt.ip_saddr} -> #{pkt.ip_daddr} #{pkt.proto.last}]\n\n" +
                         pkt.payload.strip + "\n\n"
        end
    end
end
