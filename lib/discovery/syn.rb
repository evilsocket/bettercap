=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require_relative '../logger'

# Send SYN probes trying to filling the ARP table.
class SynAgent
  def initialize( ifconfig, gw_ip, local_ip )
    @local_ip = local_ip
    @ifconfig = ifconfig
    @queue    = Queue.new

    net = ip = @ifconfig[:ip4_obj]

    # loop each ip in our subnet and push it to the queue    
    while net.include?ip
      # rescanning the gateway could cause an issue when the 
      # gateway itself has multiple interfaces ( LAN, WAN ... )
      if ip != gw_ip and ip != local_ip
        @queue.push ip
      end

      ip = ip.succ
    end

    # spawn the workers! ( tnx to https://blog.engineyard.com/2014/ruby-thread-pool )
    @workers = (0...4).map do
      Thread.new do
        begin
          while ip = @queue.pop(true)
            Logger.debug "SYN Probing #{ip} ..."

            pkt = get_packet ip.to_s

            pkt.to_w( @ifconfig[:iface] )
          end
        rescue Exception => e
          Logger.debug "#{ip} -> #{e.message}"
        end
      end
    end
  end

  def wait
    begin
      @workers.map(&:join)
    rescue Exception => e
      Logger.debug "SynAgent.wait: #{e.message}"
    end
  end

  private

  def get_packet( destination )
    pkt = PacketFu::TCPPacket.new
    pkt.ip_v      = 4
    pkt.ip_hl     = 5
    pkt.ip_tos	  = 0
    pkt.ip_len	  = 20
    pkt.ip_frag   = 0
    pkt.ip_ttl    = 115
    pkt.ip_proto  = 6	# TCP
    pkt.ip_saddr  = @local_ip
    pkt.ip_daddr  = destination
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
    pkt
  end
end

