# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

module BetterCap
module Parsers
# NTLMSS traffic parser.
class Ntlmss < Base
  # Convert binary +data+ into human readable hexadecimal representation.
  def bin2hex( data )
    hex = ''
    data.each_byte do |byte|
      if /[[:print:]]/ === byte.chr
        hex += byte.chr
      else
        hex += "\\x" + byte.to_s(16)
      end
    end
    hex
  end

  def on_packet( pkt )
    s = pkt.to_s
    if s =~ /NTLMSSP\x00\x03\x00\x00\x00.+/
      # TODO: Parse NTLMSSP packet.
      StreamLogger.log_raw( pkt, 'NTLMSS', bin2hex( pkt.payload ) )
    end
  end
end
end
end
