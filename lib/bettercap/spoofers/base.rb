# encoding: UTF-8
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
  # Hash of available spoofers ( spoofer name -> class name )
  @@loaded = {}

  class << self
    # Called when this base class is inherited from one of the spoofers.
    def inherited(subclass)
      name = subclass.name.split('::')[2].upcase
      @@loaded[name] = subclass.name
    end

    # Return a list of available spoofers names.
    def available
      @@loaded.keys
    end

    # Create an instance of a BetterCap::Spoofers object given its +name+.
    # Will raise a BetterCap::Error if +name+ is not valid.
    def get_by_name(name)
      raise BetterCap::Error, "Invalid spoofer name '#{name}'!" unless available.include? name
      BetterCap::Loader.load(@@loaded[name]).new
    end
  end

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

  # Main spoof loop repeated each +delay+ seconds.
  def spoof_loop( delay )
    loop do
      unless @running
          Logger.debug 'Stopping spoofing thread ...'
          Thread.exit
          break
      end

      Logger.debug "Spoofing #{@ctx.targets.size} targets ..."

      update_targets!

      @ctx.targets.each do |target|
        yield(target)
      end

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
