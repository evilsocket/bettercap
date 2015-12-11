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
require 'bettercap/context'

# Parse the ARP table searching for new hosts.
class ArpAgent < BaseAgent

  def self.parse( ctx )
    targets = []
    self.parse_cache do |ip,mac|
      if ip != ctx.gateway and ip != ctx.ifconfig[:ip_saddr]
        if ctx.options.ignore_ip?(ip)
          Logger.debug "Ignoring #{ip} ..."
        else
          targets << Target.new( ip, mac )
        end
      end
    end
    targets
  end

  def self.find_address( address )
    self.parse_cache do |ip,mac|
      if ip == address
        return mac
      end
    end
    nil
  end

  private

  def self.parse_cache
    arp = Shell.arp

    Logger.debug "ARP CACHE:\n#{arp}"

    arp.split("\n").each do |line|
      m = self.parse_cache_line(line)
      if !m.nil?
        ip = m[1]
        hw = m[2]
        if hw != 'ff:ff:ff:ff:ff:ff'
          yield( ip, hw )
        end
      end
    end
  end

  def self.parse_cache_line( line )
    /[^\s]+\s+\(([0-9\.]+)\)\s+at\s+([a-f0-9:]+).+#{Context.get.ifconfig[:iface]}.*/i.match(line)
  end

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
