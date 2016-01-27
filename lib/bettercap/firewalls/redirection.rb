# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
module BetterCap
module Firewalls
# This class represents a firewall port redirection rule.
class Redirection
  # Network interface name.
  attr_reader :interface
  # Protocol name.
  attr_reader :protocol
  # Source port.
  attr_reader :src_port
  # Destination address.
  attr_reader :dst_address
  # Destionation port.
  attr_reader :dst_port

  # Create the redirection rule for the specified +interface+ and +protocol+.
  # Redirect *:+src_port+ to +dst_address+:+dst_port+
  def initialize( interface, protocol, src_port, dst_address, dst_port )
    @interface   = interface
    @protocol    = protocol
    @src_port    = src_port
    @dst_address = dst_address
    @dst_port    = dst_port
  end
end
end
end
