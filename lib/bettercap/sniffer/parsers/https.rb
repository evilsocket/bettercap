# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : https://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

module BetterCap
module Parsers
# HTTPS connections parser.
class Https < Base
  @@prev = nil

  def on_packet( pkt )
    begin
      if pkt.respond_to?(:tcp_dst) and pkt.tcp_dst == 443
        Thread.new do
          hostname = BetterCap::Network.ip2name( pkt.ip_daddr )
          if @@prev.nil? or @@prev != hostname
            StreamLogger.log_raw( pkt, 'HTTPS', "https://#{hostname}/" )
            @@prev = hostname
          end
        end
      end
    rescue; end
  end

end
end
end
