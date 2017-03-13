# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

HTML email address parser:
  Author : Matteo Cantoni
  Email  : matteo.cantoni@nothink.org

This project is released under the GPL 3 license.

=end

module BetterCap
module Parsers
# HTML email address parser.
class Htmlemail < Base
  def on_packet( pkt )
    lines = pkt.to_s.split(/\r?\n/)
    lines.each do |line|
      if line =~ /(.*)\<a([^>]+)href\=\"mailto\:([^">]+)\"([^>]*)\>(.*?)\<\/a\>(.*)/i
        email = $3
        StreamLogger.log_raw( pkt, 'HTML EMAIL ADDRESS', "#{email}" )
      end
    end
  end
end
end
end
