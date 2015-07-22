=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require_relative 'base'
require 'colorize'
require 'resolv'

class HttpsParser < BaseParser
    def on_packet( pkt )
        begin
            if pkt.tcp_dst == 443
                begin
                    hostname = Resolv.getname pkt.ip_daddr
                rescue
                    hostname = pkt.ip_daddr.to_s
                end

                Logger.write "[#{pkt.ip_saddr}:#{pkt.tcp_src} > #{pkt.ip_daddr}:#{pkt.tcp_dst} #{pkt.proto.last}] " +
                             '[HTTPS] '.green +
                             "https://#{hostname}".yellow
            end
        rescue
        end
    end
end
