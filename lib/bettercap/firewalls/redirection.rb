=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
class Redirection
  attr_reader :interface, :protocol, :src_port, :dst_address, :dst_port

  def initialize( interface, protocol, src_port, dst_address, dst_port )
    @interface   = interface
    @protocol    = protocol
    @src_port    = src_port
    @dst_address = dst_address
    @dst_port    = dst_port
  end
end

