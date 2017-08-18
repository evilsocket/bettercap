# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : https://www.evilsocket.net/

UPnP SSDP broadcast discovery agent:
  Author : Brendan Coles
  Email  : bcoles[at]gmail.com

This project is released under the GPL 3 license.

=end

# Send a broadcast UPnP query trying to fill the ARP table.
module BetterCap
module Discovery
module Agents
# Class responsible for sending UPnP SSDP broadcast queries to the network.
class Upnp
  # Create a thread which will send a UPnP SSDP M-SEARCH broadcast query
  # in order to populate the ARP cache with active targets.
  # https://tools.ietf.org/html/draft-cai-ssdp-v1-03#section-4
  # https://en.wikipedia.org/wiki/Simple_Service_Discovery_Protocol
  # https://en.wikipedia.org/wiki/Zero-configuration_networking#SSDP
  def initialize( ctx, address = nil )
    host = '239.255.255.250'
    port = 1900

    pkt = PacketFu::UDPPacket.new

    pkt.eth_saddr = ctx.iface.mac
    pkt.eth_daddr = '01:00:5e:7f:ff:fa'
    pkt.ip_saddr  = ctx.iface.ip
    pkt.ip_daddr  = host
    pkt.udp_src   = (rand((2 ** 16) - 1024) + 1024).to_i
    pkt.udp_dst   = port

    query = []
    query << 'M-SEARCH * HTTP/1.1'
    query << "Host: #{host}:#{port}"
    query << 'Man: ssdp:discover'
    query << 'ST: ssdp:all'          # Search Target
    query << 'MX: 2'                 # Delay response (2 seconds)

    payload = query.join("\r\n").to_s
    payload << "\r\n"

    pkt.payload = payload
    pkt.recalc

    ctx.packets.push(pkt)
  end
end
end
end
end
