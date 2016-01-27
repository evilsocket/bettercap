# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

# Send UDP probes trying to filling the ARP table.
module BetterCap
module Discovery
module Agents
# Class responsible to send UDP probe packets to each possible IP on the network.
class Udp < Discovery::Agents::Base
  private

  # Build an UDP packet for the specified +ip+ address.
  def get_probe( ip )
    # send dummy udp packet, just to fill ARP table
    [ ip.to_s, 137, "\x10\x12\x85\x00\x00" ]
  end
end
end
end
end
