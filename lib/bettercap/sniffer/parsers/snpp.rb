=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

module BetterCap
module Parsers
# Simple Network Paging Protocol (SNPP) authentication parser.
class Snpp < Base
  def initialize
    @name = 'SNPP'
  end
  def on_packet( pkt )
    begin
      if pkt.tcp_dst == 444
        lines = pkt.to_s.split(/\r?\n/)
        lines.each do |line|
          if line =~ /LOGIn\s+(.+)\s+(.+)$/
            user = $1
            pass = $2
            StreamLogger.log_raw( pkt, @name, "username=#{user} password=#{pass}" )
          end
        end
      end
    rescue
    end
  end
end
end
end
