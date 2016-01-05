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
    port = 137
    message =
        "\x82\x28\x00\x00\x00" +
        "\x01\x00\x00\x00\x00" +
        "\x00\x00\x20\x43\x4B" +
        "\x41\x41\x41\x41\x41" +
        "\x41\x41\x41\x41\x41" +
        "\x41\x41\x41\x41\x41" +
        "\x41\x41\x41\x41\x41" +
        "\x41\x41\x41\x41\x41" +
        "\x41\x41\x41\x41\x41" +
        "\x00\x00\x21\x00\x01"

    # send netbios udp packet, just to fill ARP table
    sd = UDPSocket.new
    sd.send( message, 0, ip.to_s, port )
    sd = nil
    # TODO: Parse response for hostname?
  end
end
end
end
end
