# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : https://www.evilsocket.net/

WS-Discovery broadcast discovery agent:
  Author : Brendan Coles
  Email  : bcoles[at]gmail.com

This project is released under the GPL 3 license.

=end

# Send a broadcast WS-Discovery query trying to fill the ARP table.
module BetterCap
module Discovery
module Agents
# Class responsible for sending WS-Discovery broadcast queries to the network.
class Wsd
  # Create a thread which will send a WS-Discovery broadcast query
  # in order to populate the ARP cache with active targets.

  # References:
  # - https://msdn.microsoft.com/en-us/library/windows/desktop/bb513684(v=vs.85).aspx
  # - http://specs.xmlsoap.org/ws/2005/04/discovery/ws-discovery.pdf
  # - https://en.wikipedia.org/wiki/Web_Services_for_Devices
  # - https://en.wikipedia.org/wiki/WS-Discovery
  # - https://en.wikipedia.org/wiki/Zero-configuration_networking#WS-Discovery

  def initialize( ctx, address = nil )
    pkt = PacketFu::UDPPacket.new

    pkt.eth_saddr = ctx.iface.mac
    pkt.eth_daddr = '01:00:5e:7f:ff:fa'
    pkt.ip_saddr  = ctx.iface.ip
    pkt.ip_daddr  = '239.255.255.250'
    pkt.udp_src   = (rand((2 ** 16) - 1024) + 1024).to_i
    pkt.udp_dst   = 3702

    uuid = SecureRandom.uuid

    payload = '<?xml version="1.0" encoding="utf-8" ?>'
    payload << '<soap:Envelope'
    payload << ' xmlns:soap="http://www.w3.org/2003/05/soap-envelope"'
    payload << ' xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing"'
    payload << ' xmlns:wsd="http://schemas.xmlsoap.org/ws/2005/04/discovery"'
    payload << ' xmlns:wsdp="http://schemas.xmlsoap.org/ws/2006/02/devprof">'

    payload << '<soap:Header>'
    # WS-Discovery
    payload << '<wsa:To>urn:schemas-xmlsoap-org:ws:2005:04:discovery</wsa:To>'
    # Action (Probe)
    payload << "<wsa:Action>http://schemas.xmlsoap.org/ws/2005/04/discovery/Probe</wsa:Action>"
    # Message identifier (unique GUID)
    payload << "<wsa:MessageID>urn:uuid:#{uuid}</wsa:MessageID>"
    payload << '</soap:Header>'

    payload << '<soap:Body>'
    payload << '<wsd:Probe/>' # WS-Discovery type (blank)
    payload << '</soap:Body>'
    payload << '</env:Envelope>'

    pkt.payload = payload
    pkt.recalc

    ctx.packets.push(pkt)
  end
end
end
end
end
