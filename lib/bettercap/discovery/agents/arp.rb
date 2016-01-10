=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

# Parse the ARP table searching for new hosts.
module BetterCap
module Discovery
module Agents
# Class responsible to parse ARP cache and send ARP probes to each
# possible IP on the network.
class Arp < Discovery::Agents::Base
  # Parse the current ARP cache and return a list of BetterCap::Target
  # objects which are found inside it, using the +ctx+ BetterCap::Context
  # instance.
  def self.parse( ctx )
    targets = []
    self.parse_cache do |ip,mac|
      if ip != ctx.gateway and ip != ctx.ifconfig[:ip_saddr]
        if ctx.options.ignore_ip?(ip)
          Logger.debug "Ignoring #{ip} ..."
        else
          # reuse Target object if it's already a known address
          known = ctx.find_target ip, mac
          if known.nil?
            targets << Target.new( ip, mac )
          else
            targets << known
          end
        end
      end
    end
    targets
  end

  # Parse the ARP cache searching for the given IP +address+ and return its
  # MAC if found, otherwise nil.
  def self.find_address( address )
    self.parse_cache do |ip,mac|
      if ip == address
        return mac
      end
    end
    nil
  end

  # Parse the ARP cache searching for the given MAC +address+ and return its
  # IP if found, otherwise nil.
  def self.find_mac( address )
    self.parse_cache do |ip,mac|
      if mac == address
        return ip
      end
    end
    nil
  end

  private

  def self.parse_cache
    Shell.arp.split("\n").each do |line|
      m = self.parse_cache_line(line)
      unless m.nil?
        ip = m[1]
        hw = Target.normalized_mac( m[2] )
        if hw != 'FF:FF:FF:FF:FF:FF'
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
end
end
end
