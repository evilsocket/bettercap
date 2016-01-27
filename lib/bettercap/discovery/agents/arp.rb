# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

# Parse the ARP table searching for new hosts.
module BetterCap
module Discovery
module Agents
# Class responsible of sending ARP probes to each possible IP on the network.
class Arp < Discovery::Agents::Base
  private

  # Build a PacketFu::ARPPacket instance for the specified +ip+ address.
  def get_probe( ip )
    pkt = PacketFu::ARPPacket.new

    pkt.eth_saddr     = pkt.arp_saddr_mac = @ifconfig[:eth_saddr]
    pkt.eth_daddr     = 'ff:ff:ff:ff:ff:ff'
    pkt.arp_daddr_mac = '00:00:00:00:00:00'
    pkt.arp_saddr_ip  = @ifconfig[:ip_saddr]
    pkt.arp_daddr_ip  = ip.to_s

    pkt
  end
end
end
end
end
