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
class Udp < Base
  private

  def send_probe( ip )
    # send dummy udp packet, just to fill ARP table
    sd = UDPSocket.new
    sd.send( "\x10\x12\x85\x00\x00", 0, ip.to_s, 137 )
    sd = nil
  end
end
end
end
end
