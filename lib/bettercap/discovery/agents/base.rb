# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

# Base class for discovery agents.
module BetterCap
module Discovery
module Agents
# Base class for BetterCap::Discovery::Agents.
class Base
  # Initialize the agent using the +ctx+ BetterCap::Context instance.
  # If +address+ is not nil only that ip will be probed.
  def initialize( ctx, address = nil )
    @ctx     = ctx
    @address = address

    if @address.nil?
      net = ip = @ctx.iface.network
      # loop each ip in our subnet and push it to the queue
      while net.include?ip
        unless skip_address?(ip)
          @ctx.packets.push( get_probe(ip) )
        end
        ip = ip.succ
      end
    else
      if skip_address?(@address)
        Logger.debug "Skipping #{@address} ..."
      else
        Logger.debug "Probing #{@address} ..."
        @ctx.packets.push( get_probe(@address) )
      end
    end
  end

  private

  # Return true if +ip+ must be skipped during discovery, otherwise false.
  def skip_address?(ip)
    # don't send probes to the gateway if we already have its MAC.
    if ip == @ctx.gateway.ip
      return !@ctx.gateway.mac.nil?
    # don't send probes to our device
    elsif ip == @ctx.iface.ip
      return true
    # don't stress endpoints we already discovered
    else
      target = @ctx.find_target( ip.to_s, nil )
      # known target?
      return false if target.nil?
      # do we still need to get the mac for this target?
      return ( target.mac.nil?? false : true )
    end

  end

  # Each Discovery::Agent::Base derived class should implement this method.
  def get_probe( ip )
    Logger.warn "#{self.class.name}#get_probe not implemented!"
  end
end
end
end
end
