=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require_relative '../logger'
require_relative '../shell'
require_relative '../target'

# Parse the ARP table searching for new hosts.
class ArpAgent
  def self.parse( ctx )
    arp     = Shell.arp
    targets = []

    Logger.debug "ARP:\n#{arp}"

    arp.split("\n").each do |line|
      m = /[^\s]+\s+\(([0-9\.]+)\)\s+at\s+([a-f0-9:]+).+#{ctx.ifconfig[:iface]}.*/i.match(line)
      if !m.nil?
        if m[1] != ctx.gateway and m[1] != ctx.iface[:ip_saddr] and m[2] != 'ff:ff:ff:ff:ff:ff'
          target = Target.new( m[1], m[2] )
          targets << target
          Logger.debug "FOUND  #{target}"
        end
      end
    end

    targets
  end
end
