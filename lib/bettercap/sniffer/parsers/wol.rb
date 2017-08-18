# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : https://www.evilsocket.net/

Wake-on-LAN packet and authentication parser:
  Author : Brendan Coles
  Email  : bcoles[at]gmail.com

This project is released under the GPL 3 license.

=end

module BetterCap
module Parsers
#
# Wake-on-LAN packet and authentication parser.
#
# Supports WOL on UDP ports 0, 7 and 9
# Does not support ether-wake which uses Ethertype 0x0842
#
# References:
# - https://en.wikipedia.org/wiki/Wake-on-LAN
# - https://wiki.wireshark.org/WakeOnLAN
#
class Wol < Base
  def initialize
    @name = 'WOL'
  end

  def on_packet( pkt )
    return unless is_wol? pkt

    # Split packet into chunks of 6 bytes each.
    data = pkt.payload.to_s.unpack('H*').first.chars.each_slice(12).map(&:join)

    # The Synchronization Stream field is 6 bytes of FF
    # sync_stream = data[0]

    # The Target MAC block contains the target's MAC address
    # repeated 16 times (96 bytes)
    return unless data[1..16].uniq.size == 1

    # Format MAC address for output
    mac = data[1].upcase.scan(/\w{2}/).join(':')

    # The Password field is optional (0, 4 or 6 bytes).
    password = data[17] || 'none'

    StreamLogger.log_raw( pkt, @name, "#{'mac'.blue}=#{mac} #{'password'.blue}=#{password}" )
  rescue
  end

  private

  def is_wol?(pkt)
    return ( pkt.eth2s(:dst) == 'FF:FF:FF:FF:FF:FF' && pkt.ip_daddr == '255.255.255.255' && \
             pkt.respond_to?('udp_dst') && (pkt.udp_dst == 0 || pkt.udp_dst == 7 || pkt.udp_dst == 9) && \
             (pkt.payload.size == 102 || pkt.payload.size == 106 || pkt.payload.size == 108) && \
             pkt.payload.to_s.unpack('H*').first.start_with?('ffffffffffff') )
  end
end
end
end
