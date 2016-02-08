# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

module BetterCap
module Parsers
# MySQL authentication parser.
class MySQL < Base
  def on_packet( pkt )
    packet = Network::Protos::MySQL::Packet.parse( pkt.payload )
    unless packet.nil? or !packet.is_auth?
      StreamLogger.log_raw( pkt, 'MYSQL', "#{'username'.blue}='#{packet.username.yellow}' "\
                                          "#{'password'.blue}='#{packet.password.map { |x| sprintf("%02X", x )}.join.yellow}'" )
    end
  end
end
end
end
