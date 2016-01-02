=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require 'bettercap/sniffer/parsers/base'
require 'colorize'

module BetterCap
class PostParser < BaseParser
  def on_packet( pkt )
    s = pkt.to_s
    if s =~ /POST\s+[^\s]+\s+HTTP.+/
      StreamLogger.log_raw( pkt, "POST\n", pkt.payload )
    end
  end
end
end
