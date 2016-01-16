=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
module BetterCap
module Spoofers
# Base class for BetterCap::Spoofers modules.
class Base
  # Will raise NotImplementedError .
  def initialize
    not_implemented_method!
  end
  # Will raise NotImplementedError .
  def start
    not_implemented_method!
  end
  # Will raise NotImplementedError .
  def stop
    not_implemented_method!
  end

private

  def sniff_packets( filter )
    begin
      @capture = PacketFu::Capture.new(
          iface: @ctx.options.iface,
          filter: filter,
          start: true
      )
    rescue  Exception => e
      Logger.error e.message
    end

    @capture.stream.each do |p|
      begin
        if not @running
            Logger.debug 'Stopping thread ...'
            Thread.exit
            break
        end

        pkt = PacketFu::Packet.parse p rescue nil

        yield( pkt ) unless pkt.nil?

      rescue Exception => e
        Logger.error e.message
      end
    end
  end

  def spoof_loop( delay )
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
        yield(target)
      end

      prev_size = @ctx.targets.size

      sleep(delay)
    end
  end

  def update_gateway!
    hw = Network::Network.get_hw_address( @ctx.ifconfig, @ctx.gateway )
    raise BetterCap::Error, "Couldn't determine router MAC" if hw.nil?
    @gateway = Network::Target.new( @ctx.gateway, hw )

    Logger.info "[#{'GATEWAY'.green}] #{@gateway.to_s(false)}"
  end

  def update_targets!
    @ctx.targets.each do |target|
      # targets could change, update mac addresses if needed
      if target.mac.nil?
        hw = Network::Network.get_hw_address( @ctx.ifconfig, target.ip )
        if hw.nil?
          Logger.warn "Couldn't determine target #{ip} MAC address!"
          next
        else
          target.mac = hw
          Logger.info "[#{'TARGET'.green}] #{target.to_s(false)}"
        end
      # target was specified by MAC address
      elsif target.ip_refresh
        ip = Network::Network.get_ip_address( @ctx, target.mac )
        if ip.nil?
          Logger.warn "Couldn't determine target #{target.mac} IP address!"
          next
        else
          doprint = ( target.ip.nil? or target.ip != ip )
          target.ip = ip
          Logger.info("[#{'TARGET'.green}] #{target.to_s(false)}") if doprint
        end
      end
    end
  end

  def not_implemented_method!
    raise NotImplementedError, 'Spoofers::Base: Unimplemented method!'
  end
end
end
end
