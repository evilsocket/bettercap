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
      # rescanning the gateway could cause an issue when the
      # gateway itself has multiple interfaces ( LAN, WAN ... )
      if ip != ctx.gateway and ip != @local_ip
        packet = get_probe(ip)
        @ctx.packets.push(packet)
      end

      ip = ip.succ
    end
  end

  private

  # Each Discovery::Agent::Base derived class should implement this method.
  def get_probe( ip )
    Logger.warn "#{self.class.name}#get_probe not implemented!"
  end
end
end
end
end
