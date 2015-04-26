=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require_relative 'base'
require 'colorize'

class NtlmssParser < BaseParser
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
            Logger.write "[#{pkt.ip_saddr} > #{pkt.ip_daddr} #{pkt.proto.last}] " +
                         bin2hex( pkt.payload ).yellow
        end
    end
end
