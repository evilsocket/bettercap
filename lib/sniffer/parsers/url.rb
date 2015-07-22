=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require_relative 'base'
require 'colorize'

class UrlParser < BaseParser
    def on_packet( pkt )
        s = pkt.to_s
        if s =~ /GET\s+([^\s]+)\s+HTTP.+Host:\s+([^\s]+).+/m
            host = $2
            url = $1
            if not url =~ /.+\.(png|jpg|jpeg|bmp|gif|img|ttf|woff|css|js).*/i
                Logger.write "[#{pkt.ip_saddr}:#{pkt.tcp_src} > #{pkt.ip_daddr}:#{pkt.tcp_dst} #{pkt.proto.last}] " +
                             '[GET] '.green +
                             "http://#{host}#{url}".yellow
            end
        end
    end
end
