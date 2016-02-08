# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

module BetterCap
module Network
module Protos
module MySQL

class Packet < Network::Protos::Base
  uint24  :packet_length
  uint8   :packet_number
  uint16  :client_capabilities
  uint16  :ext_client_capabilities
  uint32  :max_packet
  uint8   :charset
  string  :padding, :size => 23, :check => "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
  stringz :username

  uint8   :plen
  bytes   :password, :size => :plen

  def is_auth?
    @packet_number == 1 and !@username.nil? and @ext_client_capabilities != 0 and @plen > 0
  end
end

end
end
end
end
