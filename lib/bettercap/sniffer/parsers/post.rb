=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require 'bettercap/sniffer/parsers/base'
require 'colorize'

class PostParser < BaseParser
    def on_packet( pkt )
        s = pkt.to_s
        if s =~ /POST\s+[^\s]+\s+HTTP.+/
            Logger.raw "[#{addr2s(pkt.ip_saddr)}:#{pkt.tcp_src} > #{addr2s(pkt.ip_daddr)}:#{pkt.tcp_dst} #{pkt.proto.last}] " +
                         "[POST]\n".green +
                         pkt.payload.strip.yellow
        end
    end
end
