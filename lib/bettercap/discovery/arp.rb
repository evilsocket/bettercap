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
require 'bettercap/discovery/base'

# Parse the ARP table searching for new hosts.
class ArpAgent < BaseAgent

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

  def self.find_address( ip )
    arp = Shell.arp
    mac = nil

    arp.split("\n").each do |line|
      m = /[^\s]+\s+\(([0-9\.]+)\)\s+at\s+([a-f0-9:]+).+#{ctx.ifconfig[:iface]}.*/i.match(line)
      if !m.nil?
        if m[1] == ip and m[2] != 'ff:ff:ff:ff:ff:ff'
          mac = m[2]
        end
      end
    end

    mac
  end

  private

  def send_probe( ip )
    pkt = PacketFu::ARPPacket.new

    pkt.eth_saddr     = pkt.arp_saddr_mac = @ifconfig[:eth_saddr]
    pkt.eth_daddr     = 'ff:ff:ff:ff:ff:ff'
    pkt.arp_daddr_mac = '00:00:00:00:00:00'
    pkt.arp_saddr_ip  = @ifconfig[:ip_saddr]
    pkt.arp_daddr_ip  = ip

    pkt.to_w( @ifconfig[:iface] )
  end
end
