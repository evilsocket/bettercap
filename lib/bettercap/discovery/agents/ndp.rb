# Parse the NDP table searching for new hosts.
module BetterCap
module Discovery
module Agents
# Class responsible of sending NDP probes to each possible IP on the network.
class Ndp < Discovery::Agents::Base
  private

  # Send a Neighbor Solicitation packet in order to update neighbor discovery table,
  #  with target's mac.
  # The packet is a broadcast message, so mac is created by "33:33:ff" prefix plus the
  # 24 least significant bits of the address.
  # Similar rule applies to the destination address. Multicast address is formed from
  # the network prefix ff02::1:ff00:0/104 and the 24 least significant bits of the address.
  def get_probe( ip )
    split_ip = ip.split(':')
    dst_mac = "33:33:ff:" + split_ip[-2][-2,2] + ":" + split_ip[-1][0,2] + ":" + split_ip[-1][2,2]
    dst_ip = "ff02::1:ff" + split_ip[-2][-2,2] + ":" + split_ip[-1]

    p = PacketFu::NDPPacket.new

    p.eth_daddr = dst_mac
    p.eth_saddr = @ctx.iface.mac
    p.eth_proto = 0x86dd

    p.ipv6_saddr = @ctx.iface.ip
    p.ipv6_daddr = dst_ip

    p.ndp_type = 135
    p.ndp_taddr = ip.to_s
    p.ndp_opt_type = 1
    p.ndp_opt_len = 1
    p.ndp_lladdr = @ctx.iface.mac

    p.ipv6_recalc
    p.ndp_recalc

    p
  end
end
end
end
end
