# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

HTML phone number parser:
  Author : Matteo Cantoni
  Email  : matteo.cantoni@nothink.org

This project is released under the GPL 3 license.

=end

module BetterCap
module Parsers
# HTML phone number parser.
class Htmlphone < Base
  def on_packet( pkt )
    phone_mask = '((\d)\-(\d){3}\-(\d){3}\-(\d){3})'
    lines = pkt.to_s.split(/\r?\n/)
    lines.each do |line|
      if line =~ /(.*)#{phone_mask}(.*)/im
        phone_number = $2
        StreamLogger.log_raw( pkt, 'HTML PHONE NUMBER', "#{phone_number}" )
      end
    end
  end
end
end
end
