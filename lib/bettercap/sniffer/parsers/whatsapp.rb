# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

WhatsApp OS Parser:
  Author : Gianluca Costa
  Email  : g.costa@xplico.org

This project is released under the GPL 3 license.

=end

module BetterCap
module Parsers
# HTTP GET requests parser.
class Whatsapp < Base
  def initialize
    @name = 'WHATSAPP'
  end
  # Convert binary +data+ into human readable hexadecimal representation.
  def wa_phone( data )
    phone = ''
    data.each_byte do |byte|
      if /[[:print:]]/ === byte.chr
        phone += byte.chr
      else
        if phone.length > 4
            break
        else
            phone = ''
        end
      end
    end
    phone
  end
  def on_packet( pkt )
    begin
      if pkt.tcp_dst == 443 or pkt.tcp_dst == 5222
        if pkt.payload[0,2] == "WA"
          s = wa_phone(pkt.payload)
          StreamLogger.log_raw( pkt, @name, s )
        end
      end
    rescue
    end
  end
end
end
end
