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
  IP_ADDRESS_REGEX = '\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3}'

  # Return true if +ip+ is a valid IP address, otherwise false.
  def is_ip?(ip)
    if /\A(#{IP_ADDRESS_REGEX})\Z/ =~ ip.to_s
      return $~.captures.all? {|i| i.to_i < 256}
    end
    false
  end

  # Return true if +r+ is a valid IP address range ( 192.168.1.1-93 ), otherwise false.
  def is_range?(r)
    if /\A(#{IP_ADDRESS_REGEX})\-(\d{1,3})\Z/ =~ r.to_s
      return $~.captures.all? {|i| i.to_i < 256}
    end
    false
  end

  # Return true if +n+ is a valid IP netmask range ( 192.168.1.1/24 ), otherwise false.
  def is_netmask?(n)
    if /\A(#{IP_ADDRESS_REGEX})\/(\d+)\Z/ =~ n.to_s
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
  def get_hw_address( ctx, ip )
    hw = ArpReader.find_address( ip )
    if hw.nil?
      start_agents( ctx, ip )
      hw = ArpReader.find_address( ip )
    end
    hw
  end

  private

  # Start discovery agents and wait for +ctx.timeout+ seconds for them to
  # complete their job.
  # If +address+ is not nil only that ip will be probed.
  def start_agents( ctx, address = nil )
    [ 'Icmp', 'Udp', 'Arp' ].each do |name|
      BetterCap::Loader.load("BetterCap::Discovery::Agents::#{name}").new(ctx, address)
    end
    ctx.packets.wait_empty( ctx.timeout )
  end

end
end
end
