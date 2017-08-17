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
# DHCP packets and authentication parser.
class DHCP < Base
  def on_packet( pkt )
    return unless (pkt.udp_dst == 67 || pkt.udp_dst == 68)

    packet = Network::Protos::DHCP::Packet.parse( pkt.payload )

    return if packet.nil?

    auth = packet.authentication
    cid  = auth.nil?? nil : packet.client_identifier
    msg  = "[#{packet.type.yellow}] #{'Transaction-ID'.green}=#{sprintf( "0x%X", packet.xid ).yellow}"

    unless cid.nil?
      msg += " #{'Client-ID'.green}='#{cid.yellow}'"
    end

    unless auth.nil?
      msg += "\n#{'AUTHENTICATION'.green}:\n\n"
      auth.each do |k,v|
        msg += "  #{k.blue} : #{v.yellow}\n"
      end
      msg += "\n"
    end

    StreamLogger.log_raw( pkt, 'DHCP', msg )
  rescue
  end
end
end
end
