=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require_relative 'base'
require 'colorize'

class PostParser < BaseParser
    def on_packet( pkt )
        s = pkt.to_s
        if s =~ /POST\s+[^\s]+\s+HTTP.+/
            Logger.write "[#{pkt.ip_saddr}:#{pkt.tcp_src} > #{pkt.ip_daddr}:#{pkt.tcp_dst} #{pkt.proto.last}]\n" +
                         pkt.payload.strip.yellow
        end
    end
end
