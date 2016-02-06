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
# WhatsApp traffic parser.
class Whatsapp < Base
  def on_packet( pkt )
    begin
      if ( pkt.tcp_dst == 443 or pkt.tcp_dst == 5222 or pkt.tcp_dst == 5223 ) and pkt.payload =~ /^WA.*?([a-zA-Z\-\.0-9]+).*?([0-9]+)/
        version = $1
        phone = $2
        StreamLogger.log_raw( pkt, 'WHATSAPP', "#{'phone'.green}=#{phone.yellow} #{'version'.green}=#{version.yellow}" )
      end
    rescue; end
  end
end
end
end
