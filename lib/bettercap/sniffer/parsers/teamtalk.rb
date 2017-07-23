=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : https://www.evilsocket.net/

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
    begin
      if pkt.tcp_dst == 10333 || pkt.udp_dst == 10333
        lines = pkt.to_s.split(/\r?\n/)
        lines.each do |line|
          if line =~ /login\s+/
            if line =~ /username=/ && line =~ /password=/
              version = line.scan(/version="?([\d\.]+)"?\s/).flatten.first
              user = line.scan(/username="?(.*?)"?\s/).flatten.first
              pass = line.scan(/password="?(.*?)"?\s/).flatten.first
              StreamLogger.log_raw( pkt, @name, "#{'version'.blue}=#{version} username=#{user} password=#{pass}" )
            end
          end
        end
      end
    rescue
    end
  end
end
end
end
