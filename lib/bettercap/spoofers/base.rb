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

  # Will create a PacketFu::Capture object using the specified +filter+ and
  # will yield every parsed packet to the given code block.
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

  # Print informations about new and lost targets.
  def print_differences( prev_targets )
    size      = @ctx.targets.size
    prev_size = prev_targets.size
    diff      = nil
    label     = nil

    if size > prev_size
      diff  = @ctx.targets - prev_targets
      delta = diff.size
      label = 'NEW'.green

      Logger.warn "Acquired #{delta} new target#{if delta > 1 then "s" else "" end}."
    elsif size < prev_size
      diff  = prev_targets - @ctx.targets
      delta = diff.size
      label = 'LOST'.red

      Logger.warn "Lost #{delta} target#{if delta > 1 then "s" else "" end}."
    end

    unless diff.nil?
      msg = "\n"
      diff.each do |target|
        msg += "  [#{label}] #{target.to_s(false)}\n"
      end
      msg += "\n"
      Logger.raw msg
    end
  end

  # Main spoof loop repeated each +delay+ seconds.
  def spoof_loop( delay )
    prev_targets = @ctx.targets

    loop do
      unless @running
          Logger.debug 'Stopping spoofing thread ...'
          Thread.exit
          break
      end

      print_differences prev_targets

      Logger.debug "Spoofing #{@ctx.targets.size} targets ..."

      update_targets!

      @ctx.targets.each do |target|
        yield(target)
      end

      prev_targets = @ctx.targets

      sleep(delay)
    end
  end

  # Get the MAC address of the gateway and update it.
  def update_gateway!
    hw = Network.get_hw_address( @ctx.ifconfig, @ctx.gateway )
    raise BetterCap::Error, "Couldn't determine router MAC" if hw.nil?
    @gateway = Network::Target.new( @ctx.gateway, hw )

    Logger.info "[#{'GATEWAY'.green}] #{@gateway.to_s(false)}"
  end

  # Update each target that needs to be updated.
  def update_targets!
    @ctx.targets.each do |target|
      # targets could change, update mac addresses if needed
      if target.mac.nil?
        hw = Network.get_hw_address( @ctx.ifconfig, target.ip )
        if hw.nil?
          Logger.warn "Couldn't determine target #{ip} MAC address!"
          next
        else
          target.mac = hw
          Logger.info "[#{'TARGET'.green}] #{target.to_s(false)}"
        end
      # target was specified by MAC address
      elsif target.ip_refresh
        ip = Network.get_ip_address( @ctx, target.mac )
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

  # Used to raise a NotImplementedError exception.
  def not_implemented_method!
    raise NotImplementedError, 'Spoofers::Base: Unimplemented method!'
  end
end
end
end
