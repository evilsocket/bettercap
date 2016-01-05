=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require 'thread'

module BetterCap
class Network
    class << self
    def is_ip?(ip)
      if /\A(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})\Z/ =~ ip.to_s
        return $~.captures.all? {|i| i.to_i < 256}
      end
      false
    end

    def is_mac?(mac)
      ( /^[a-f0-9]{1,2}\:[a-f0-9]{1,2}\:[a-f0-9]{1,2}\:[a-f0-9]{1,2}\:[a-f0-9]{1,2}\:[a-f0-9]{1,2}$/i =~ mac.to_s )
    end

    def get_gateway
      nstat = Shell.execute('netstat -nr')

      Logger.debug "NETSTAT:\n#{nstat}"

      out = nstat.split(/\n/).select {|n| n =~ /UG/ }
      gw  = nil
      out.each do |line|
        if line.include?( Context.get.options.iface )
          tmp = line.split[1]
          if is_ip?(tmp)
            gw = tmp
            break
          end
        end
      end
      gw
    end

    def get_local_ips
      ips = []

      Shell.ifconfig.split("\n").each do |line|
        if line =~ /inet [adr:]*([\d\.]+)/
          ips << $1
        end
      end

      ips
    end

    def get_alive_targets( ctx, timeout = 5 )
      if ctx.options.should_discover_hosts?
        start_agents( ctx, timeout )
      else
        Logger.debug 'Using current ARP cache.'
      end

      Discovery::Agents::Arp.parse ctx
    end

    def get_ip_address( ctx, mac, timeout = 5 )
      ip = Discovery::Agents::Arp.find_mac( mac )
      if ip.nil?
        start_agents( ctx, timeout )
        ip = Discovery::Agents::Arp.find_mac( mac )
      end
      ip
    end

=begin
  Apparently on Mac OSX the gem pcaprub ( or libpcap itself ) has
  a bug, so we can't use 'PacketFu::Utils::arp' since the funtion
  it's using:

  if cap.save > 0
    ...
  end

  won't catch anything, instead we're using cap.stream.each.
=end
    def get_hw_address( iface, ip_address, attempts = 2 )
      hw_address = Discovery::Agents::Arp.find_address( ip_address )

      if hw_address.nil?
        attempts.times do
          arp_pkt = PacketFu::ARPPacket.new

          arp_pkt.eth_saddr     = arp_pkt.arp_saddr_mac = iface[:eth_saddr]
          arp_pkt.eth_daddr     = 'ff:ff:ff:ff:ff:ff'
          arp_pkt.arp_daddr_mac = '00:00:00:00:00:00'
          arp_pkt.arp_saddr_ip  = iface[:ip_saddr]
          arp_pkt.arp_daddr_ip  = ip_address

          cap_thread = Thread.new do
            target_mac = nil
            timeout = 0

            cap = PacketFu::Capture.new(
              iface: iface[:iface],
              start: true,
              filter: "arp src #{ip_address} and ether dst #{arp_pkt.eth_saddr}"
            )
            arp_pkt.to_w(iface[:iface])

            begin
              Logger.debug 'Attempting to get MAC from packet capture ...'
              target_mac = Timeout::timeout(0.5) { get_mac_from_capture(cap, ip_address) }
            rescue Timeout::Error
              timeout += 0.1
              retry if target_mac.nil? && timeout <= 5
            end

            target_mac
          end
          hw_address = cap_thread.value

          break unless hw_address.nil?
        end
      end

      hw_address
    end

    private

    def start_agents( ctx, timeout )
      icmp = Discovery::Agents::Icmp.new timeout
      udp  = Discovery::Agents::Udp.new ctx.ifconfig, ctx.gateway, ctx.ifconfig[:ip_saddr]
      arp  = Discovery::Agents::Arp.new ctx.ifconfig, ctx.gateway, ctx.ifconfig[:ip_saddr]

      icmp.wait
      arp.wait
      udp.wait
    end

    def get_mac_from_capture( cap, ip_address )
      cap.stream.each do |p|
        arp_response = PacketFu::Packet.parse(p)
        target_mac = arp_response.arp_saddr_mac if arp_response.arp_saddr_ip == ip_address
        break target_mac unless target_mac.nil?
      end
    end
  end
end
end
