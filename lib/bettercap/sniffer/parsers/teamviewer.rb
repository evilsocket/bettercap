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
# MySQL authentication parser.
class TeamViewer < Base
  def on_packet( pkt )
    return unless (pkt.tcp_dst == 5938 || pkt.tcp_src == 5938)

    packet = Network::Protos::TeamViewer::Packet.parse( pkt.payload )

    return if packet.nil?

    StreamLogger.log_raw( pkt, 'TEAMVIEWER', "#{'version'.blue}=#{packet.version.yellow} #{'command'.blue}=#{packet.command.yellow}"  )
  rescue
  end
end
end
end
