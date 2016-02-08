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
  def initialize( ctx )
    @ctx       = ctx
    @ifconfig  = ctx.ifconfig
    @local_ip  = @ifconfig[:ip_saddr]

    net = ip = @ifconfig[:ip4_obj]
    # loop each ip in our subnet and push it to the queue
    while net.include?ip
      unless skip_address?(ip)
        @ctx.packets.push( get_probe(ip) )
      end
      ip = ip.succ
    end
  end

  private

  # Return true if +ip+ must be skipped during discovery, otherwise false.
  def skip_address?(ip)
    # don't send probes to the gateway
    ( ip == @ctx.gateway or \
      # don't send probes to our device
      ip == @local_ip or \
      # don't stress endpoints we already discovered
      !@ctx.find_target( ip.to_s, nil ).nil? )
  end

  # Each Discovery::Agent::Base derived class should implement this method.
  def get_probe( ip )
    Logger.warn "#{self.class.name}#get_probe not implemented!"
  end
end
end
end
end
