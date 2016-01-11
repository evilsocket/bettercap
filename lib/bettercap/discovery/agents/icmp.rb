=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

# Send a broadcast ping trying to filling the ARP table.
module BetterCap
module Discovery
module Agents
# Class responsible to do a ping-sweep on the network.
class Icmp
  # Create a thread which will perform a ping-sweep on the network in order
  # to populate the ARP cache with active targets, with a +ctx.timeout+ seconds
  # timeout.
  def initialize( ctx )
    @thread = ::Thread.new {
      Factories::Firewall.get.enable_icmp_bcast(true)
      
      # TODO: Use the real broadcast address for this network.
      3.times do
        pkt = PacketFu::ICMPPacket.new

        pkt.eth_saddr = ctx.ifconfig[:eth_saddr]
        pkt.eth_daddr = 'ff:ff:ff:ff:ff:ff'
        pkt.ip_saddr  = ctx.ifconfig[:ip_saddr]
        pkt.ip_daddr  = '255.255.255.255'
        pkt.icmp_type = 8
        pkt.icmp_code = 0
        pkt.payload   = "ABCD"
        pkt.recalc

        pkt.to_w( ctx.ifconfig[:iface] )

        sleep(0.5)
      end
    }
  end

  # Wait for the ping-sweep thread to be finished.
  def wait
    begin
      @thread.join
    rescue Exception => e
      Logger.debug "Discovery::Agents::Icmp.wait: #{e.message}"
    end
  end
end
end
end
end
