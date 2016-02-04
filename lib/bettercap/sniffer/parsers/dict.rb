=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

module BetterCap
module Parsers
# DICT authentication parser.
class Dict < Base
  def initialize
    @name = 'DICT'
  end
  def on_packet( pkt )
    begin
      if pkt.tcp_dst == 2628
        lines = pkt.to_s.split(/\r?\n/)
        lines.each do |line|
          if line =~ /AUTH\s+(.+)\s+(.+)$/
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
