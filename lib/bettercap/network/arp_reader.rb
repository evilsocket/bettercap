# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require 'bettercap/error'

module BetterCap
module Network
# This class is responsible for reading the computer ARP table.
class ArpReader
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

  # Read the computer ARP cache and parse each line, it will yield each
  # ip and mac address it will be able to extract.
  def self.parse_cache
    iface = Context.get.ifconfig[:iface]
    Shell.arp.split("\n").each do |line|
      m = self.parse_cache_line(iface,line)
      unless m.nil?
        ip = m[1]
        hw = Target.normalized_mac( m[2] )
        if hw != 'FF:FF:FF:FF:FF:FF'
          yield( ip, hw )
        end
      end
    end
  end

  # Parse a single ARP cache +line+ related to the +iface+ network interface.
  def self.parse_cache_line( iface, line )
    /[^\s]+\s+\(([0-9\.]+)\)\s+at\s+([a-f0-9:]+).+#{iface}.*/i.match(line)
  end
end
end
end
