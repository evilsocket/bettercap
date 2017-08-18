# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : https://www.evilsocket.net/

mDNS DNS-SD broadcast discovery agent:
  Author : Brendan Coles
  Email  : bcoles[at]gmail.com

This project is released under the GPL 3 license.

=end

# Send a broadcast mDNS query trying to fill the ARP table.
module BetterCap
module Discovery
module Agents
# Class responsible for sending mDNS broadcast queries to the network.
class Mdns
  # Create a thread which will send an mDNS broadcast query
  # in order to populate the ARP cache with active targets.
  # http://www.multicastdns.org/
  # http://www.ietf.org/rfc/rfc6762.txt
  # https://en.wikipedia.org/wiki/Multicast_DNS
  # https://en.wikipedia.org/wiki/Zero-configuration_networking#DNS-SD_with_multicast
  def initialize( ctx, address = nil )
    pkt = PacketFu::UDPPacket.new

    pkt.eth_saddr = ctx.iface.mac
    pkt.eth_daddr = '01:00:5e:00:00:fb'
    pkt.ip_saddr  = ctx.iface.ip
    pkt.ip_daddr  = '224.0.0.251'
    pkt.udp_src   = (rand((2 ** 16) - 1024) + 1024).to_i
    pkt.udp_dst   = 5353

    query = "\x09_services\x07_dns-sd\x04_udp\x05local"

    payload =  "\x00\x01" # Transaction ID
    payload << "\x00\x00" # Flags
    payload << "\x00\x01" # Number of questions
    payload << "\x00\x00" # Number of answers
    payload << "\x00\x00" # Number of authority resource records
    payload << "\x00\x00" # Number of additional resource records
    payload << query      # Query
    payload << "\x00"     # Terminator
    payload << "\x00\x0c" # Type (PTR)
    payload << "\x00\x01" # Class

    pkt.payload = payload
    pkt.recalc

    ctx.packets.push(pkt)
  end
end
end
end
end
