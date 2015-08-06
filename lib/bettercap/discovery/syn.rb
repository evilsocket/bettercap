=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require 'bettercap/discovery/base'

# Send SYN probes trying to filling the ARP table.
module BetterCap
  class SynAgent < BaseAgent
    private

    def send_probe( ip )
      pkt = PacketFu::TCPPacket.new
      pkt.ip_v      = 4
      pkt.ip_hl     = 5
      pkt.ip_tos	  = 0
      pkt.ip_len	  = 20
      pkt.ip_frag   = 0
      pkt.ip_ttl    = 115
      pkt.ip_proto  = 6	# TCP
      pkt.ip_saddr  = @local_ip
      pkt.ip_daddr  = ip
      pkt.payload   = "\xC\x0\xF\xF\xE\xE"
      pkt.tcp_flags.ack  = 0
      pkt.tcp_flags.fin  = 0
      pkt.tcp_flags.psh  = 0
      pkt.tcp_flags.rst  = 0
      pkt.tcp_flags.syn  = 1
      pkt.tcp_flags.urg  = 0
      pkt.tcp_ecn        = 0
      pkt.tcp_win	       = 8192
      pkt.tcp_hlen       = 5
      pkt.tcp_dst        = rand(1024..65535)
      pkt.recalc

      pkt.to_w( @ifconfig[:iface] )
    end
  end
end
