=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require 'bettercap/logger'
require 'colorize'

class BaseParser
  def initialize
    @filters = []
    @name = 'BASE'
  end

  def on_packet( pkt )
    s = pkt.to_s
    @filters.each do |filter|
      if s =~ filter
        Logger.write "[#{pkt.ip_saddr}:#{pkt.tcp_src} > #{pkt.ip_daddr}:#{pkt.tcp_dst} #{pkt.proto.last}] " +
                     "[#{@name}] ".green +
                     pkt.payload.strip.yellow
      end
    end
  end
end
