# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require 'thread'

module BetterCap
# Handles various network related tasks.
module Network
class << self
  # Return true if +ip+ is a valid IP address, otherwise false.
  def is_ip?(ip)
    if /\A(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})\Z/ =~ ip.to_s
      return $~.captures.all? {|i| i.to_i < 256}
    end
    false
  end

  # Return true if +mac+ is a valid MAC address, otherwise false.
  def is_mac?(mac)
    ( /^[a-f0-9]{1,2}\:[a-f0-9]{1,2}\:[a-f0-9]{1,2}\:[a-f0-9]{1,2}\:[a-f0-9]{1,2}\:[a-f0-9]{1,2}$/i =~ mac.to_s )
  end

  # Return the current network gateway or nil.
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

  # Return a list of IP addresses associated to this device network interfaces.
  def get_local_ips
    ips = []

    if Shell.available?('ip')
      Shell.ip.split("\n").each do |line|
        if line.strip =~ /^inet\s+([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)\/(\d+).+$/i
          ips << $1
        end
      end
    else
      Shell.ifconfig.split("\n").each do |line|
        if line =~ /inet [adr:]*([\d\.]+)/
          ips << $1
        end
      end
    end

    ips
  end

  # Return a list of BetterCap::Target objects found on the network, given a
  # BetterCap::Context ( +ctx+ ) and a +timeout+ in seconds for the operation.
  def get_alive_targets( ctx )
    if ctx.options.should_discover_hosts?
      start_agents( ctx )
    else
      Logger.debug 'Using current ARP cache.'
    end

    ArpReader.parse ctx
  end

  # Return the IP address associated with the +mac+ hardware address using the
  # given BetterCap::Context ( +ctx+ ).
  def get_ip_address( ctx, mac )
    ip = ArpReader.find_mac( mac )
    if ip.nil?
      start_agents( ctx )
      ip = ArpReader.find_mac( mac )
    end
    ip
  end

  # Return the hardware address associated with the specified +ip_address+ using
  # the +iface+ network interface.
  # The resolution will be performed for the specified number of +attempts+.
  def get_hw_address( iface, ip_address, attempts = 2 )
    hw_address = ArpReader.find_address( ip_address )

    if hw_address.nil?
      attempts.times do
        arp_pkt = PacketFu::ARPPacket.new

        arp_pkt.eth_saddr     = arp_pkt.arp_saddr_mac = iface[:eth_saddr]
        arp_pkt.eth_daddr     = 'ff:ff:ff:ff:ff:ff'
        arp_pkt.arp_daddr_mac = '00:00:00:00:00:00'
        arp_pkt.arp_saddr_ip  = iface[:ip_saddr]
        arp_pkt.arp_daddr_ip  = ip_address

        cap_thread = Thread.new do
          Context.get.packets.push(arp_pkt)

          target_mac = nil
          timeout = 0

          cap = PacketFu::Capture.new(
            iface: iface[:iface],
            start: true,
            filter: "arp src #{ip_address} and ether dst #{arp_pkt.eth_saddr}"
          )

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

  # Start discovery agents and wait for +ctx.timeout+ seconds for them to
  # complete their job.
  def start_agents( ctx )
    [ 'Icmp', 'Udp', 'Arp' ].each do |name|
      BetterCap::Loader.load("BetterCap::Discovery::Agents::#{name}").new(ctx)
    end
    ctx.packets.wait_empty( ctx.timeout )
  end

  # Search for the MAC address associated to +ip_address+ inside the +cap+
  # PacketFu::Capture object.
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
