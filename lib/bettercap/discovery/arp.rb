=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require 'bettercap/logger'
require 'bettercap/shell'
require 'bettercap/target'

# Parse the ARP table searching for new hosts.
class ArpAgent
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
            Logger.debug "ARP Probing #{ip} ..."

            pkt = PacketFu::ARPPacket.new

            pkt.eth_saddr     = pkt.arp_saddr_mac = @ifconfig[:eth_saddr]
            pkt.eth_daddr     = 'ff:ff:ff:ff:ff:ff'
            pkt.arp_daddr_mac = '00:00:00:00:00:00'
            pkt.arp_saddr_ip  = @ifconfig[:ip_saddr]
            pkt.arp_daddr_ip  = ip.to_s

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
      Logger.debug "ArpAgent.wait: #{e.message}"
    end
  end

  def self.parse( ctx )
    arp     = Shell.arp
    targets = []

    Logger.debug "ARP:\n#{arp}"

    arp.split("\n").each do |line|
      m = /[^\s]+\s+\(([0-9\.]+)\)\s+at\s+([a-f0-9:]+).+#{ctx.ifconfig[:iface]}.*/i.match(line)
      if !m.nil?
        if m[1] != ctx.gateway and m[1] != ctx.ifconfig[:ip_saddr] and m[2] != 'ff:ff:ff:ff:ff:ff'
          target = Target.new( m[1], m[2] )
          targets << target
          Logger.debug "FOUND  #{target}"
        end
      end
    end

    targets
  end
end
