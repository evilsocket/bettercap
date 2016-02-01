# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require 'resolv'

module BetterCap
module Parsers
# HTTPS connections parser.
class Https < Base
  @@prev = nil

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

          if @@prev.nil? or @@prev != hostname
            StreamLogger.log_raw( pkt, 'HTTPS', "https://#{hostname}/" )
            @@prev = hostname
          end
        end
      end
    rescue
    end
  end
end
end
end
