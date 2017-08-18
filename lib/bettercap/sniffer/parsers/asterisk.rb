=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : https://www.evilsocket.net/

Asterisk Call Manager authentication parser:
  Author : Brendan Coles
  Email  : bcoles[at]gmail.com

This project is released under the GPL 3 license.

=end

module BetterCap
module Parsers
# Asterisk Call Manager authentication parser.
class Asterisk  < Base
  def initialize
    @name = 'Asterisk'
  end
  def on_packet( pkt )
    return unless pkt.tcp_dst == 5038
    return unless pkt.to_s =~ /action:\s+login\r?\n/i

    if pkt.to_s =~ /username:\s+(.+?)\r?\n/i && pkt.to_s =~ /secret:\s+(.+?)\r?\n/i
      user = pkt.to_s.scan(/username:\s+(.+?)\r?\n/i).flatten.first
      pass = pkt.to_s.scan(/secret:\s+(.+?)\r?\n/i).flatten.first
      StreamLogger.log_raw( pkt, @name, "username=#{user} password=#{pass}" )
    end
  rescue
  end
end
end
end
