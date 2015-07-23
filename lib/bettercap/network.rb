=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require 'thread'

require 'bettercap/error'
require 'bettercap/logger'
require 'bettercap/shell'
require 'bettercap/target'
require 'bettercap/factories/firewall_factory'
require 'bettercap/discovery/icmp'
require 'bettercap/discovery/udp'
require 'bettercap/discovery/syn'
require 'bettercap/discovery/arp'

class Network

  def Network.is_ip?(ip)
    if /\A(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})\Z/ =~ ip.to_s
      return $~.captures.all? {|i| i.to_i < 256}
    end
    false
  end

  def Network.get_gateway
    nstat = Shell.execute('netstat -nr')

    Logger.debug "NETSTAT:\n#{nstat}"
      
    out = nstat.split(/\n/).select {|n| n =~ /UG/ }
    gw = out.first.split[1]

    raise BetterCap::Error, 'Could not detect gateway address' unless is_ip?(gw)
    gw
  end

  def Network.get_local_ips
    ips = []
    
    Shell.ifconfig.split("\n").each do |line|
      if line =~ /inet [adr:]*([\d\.]+)/
        ips << $1
      end
    end

    ips
  end

  def Network.get_alive_targets( ctx, timeout = 5 )
    if ctx.options[:arpcache] == false
      icmp = IcmpAgent.new timeout
      udp = UdpAgent.new ctx.ifconfig, ctx.gateway, ctx.iface[:ip_saddr]
      syn = SynAgent.new ctx.ifconfig, ctx.gateway, ctx.iface[:ip_saddr]

      syn.wait
      icmp.wait
      udp.wait
    else
      Logger.debug 'Using current ARP cache.'
    end

    ArpAgent.parse ctx
  end

=begin
  FIXME:

  Apparently on Mac OSX the gem pcaprub ( or libpcap itself ) has
  a bug, so we can't use 'PacketFu::Utils::arp' since the funtion
  it's using:

  if cap.save > 0
    ...
  end

  won't catch anything, instead we're using cap.stream.each.
=end
  def Network.get_hw_address( iface, ip_address, attempts = 2 )
    hw_address = nil

    attempts.times do
      arp_pkt = PacketFu::ARPPacket.new

      arp_pkt.eth_saddr     = arp_pkt.arp_saddr_mac = iface[:eth_saddr]
      arp_pkt.eth_daddr     = 'ff:ff:ff:ff:ff:ff'
      arp_pkt.arp_daddr_mac = '00:00:00:00:00:00'
      arp_pkt.arp_saddr_ip  = iface[:ip_saddr]
      arp_pkt.arp_daddr_ip  = ip_address

      cap_thread = Thread.new do
        target_mac = nil
        cap = PacketFu::Capture.new(
          :iface => iface[:iface],
          :start => true,
          :filter => "arp src #{ip_address} and ether dst #{arp_pkt.eth_saddr}"
        )
        arp_pkt.to_w(iface[:iface])

        timeout = 0

        while target_mac.nil? && timeout <= 5
          cap.stream.each do |p|
            arp_response = PacketFu::Packet.parse(p)
            target_mac = arp_response.arp_saddr_mac if arp_response.arp_saddr_ip == ip_address

            break unless target_mac.nil?
          end

          timeout += 0.1

          Logger.debug 'Retrying ...'
          sleep 0.1
        end
        target_mac
      end
      hw_address = cap_thread.value

      break unless hw_address.nil?
    end

    hw_address
  end
end
