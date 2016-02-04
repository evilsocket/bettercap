=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

module BetterCap
module Parsers
# Redis authentication parser.
class Redis < Base
  def initialize
    @name = 'REDIS'
  end
  def on_packet( pkt )
    begin
      if pkt.tcp_dst == 6379
        lines = pkt.to_s.split(/\r?\n/)
        lines.each do |line|
          if line =~ /config\s+set\s+requirepass\s+(.+)$/i
            pass = "#{$1}"
            StreamLogger.log_raw( pkt, @name, "password=#{pass}" )
          elsif line =~ /AUTH\s+(.+)$/i
            pass = "#{$1}"
            StreamLogger.log_raw( pkt, @name, "password=#{pass}" )
          end
        end
      end
    rescue
    end
  end
end
end
end
