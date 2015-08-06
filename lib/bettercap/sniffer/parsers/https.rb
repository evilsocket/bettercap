=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require 'bettercap/sniffer/parsers/base'
require 'colorize'
require 'resolv'

module BetterCap
  class HttpsParser < BaseParser
    def on_packet( pkt )
      begin
        if pkt.tcp_dst == 443
          # the DNS resolution could take a while and block other parsers.
          Thread.new do
            begin
              hostname = Resolv.getname pkt.ip_daddr
            rescue
              hostname = pkt.ip_daddr.to_s
            end

            Logger.write "[#{pkt.ip_saddr}:#{pkt.tcp_src} > #{pkt.ip_daddr}:#{pkt.tcp_dst} #{pkt.proto.last}] " +
            '[HTTPS] '.green +
              "https://#{hostname}/".yellow
          end
        end
      rescue
      end
    end
  end
end
