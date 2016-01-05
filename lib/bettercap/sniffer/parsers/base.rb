=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
module BetterCap
module Parsers
# Base class for BetterCap::Parsers.
class Base
  # Initialize this parser.
  def initialize
    @filters = []
    @name = 'BASE'
  end

  # This method will be called from the BetterCap::Sniffer for each
  # incoming packet ( +pkt ) and will apply the parser filter to it.
  def on_packet( pkt )
    s = pkt.to_s
    @filters.each do |filter|
      if s =~ filter
        StreamLogger.log_raw( pkt, @name, pkt.payload )
      end
    end
  end
end
end
end
