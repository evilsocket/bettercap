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
# Just keep track of UDP connections.
class UDP < Base
  def on_packet( pkt )
    begin
      if pkt.is_udp?
        StreamLogger.log_raw( pkt, 'UDP', "#{pkt.payload.size} bytes" )
      end
    rescue; end
  end
end
end
end
