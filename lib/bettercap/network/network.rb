# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

module BetterCap
# Handles various network related tasks.
module Network
class << self
  # Return the current network gateway or nil.
  def get_gateway
    nstat = Shell.execute('netstat -nr')
    iface = Context.get.options.core.iface

    Logger.debug "NETSTAT:\n#{nstat}"

    nstat.split(/\n/).select {|n| n =~ /UG/ }.each do |line|
      Network::Validator.each_ip(line) do |address|
        return address
      end
    end
    nil
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
    if ctx.options.core.discovery?
      start_agents( ctx )
    else
      sleep(0.3)
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
