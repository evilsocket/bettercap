# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

HTML title parser:
  Author : Matteo Cantoni
  Email  : matteo.cantoni@nothink.org

This project is released under the GPL 3 license.

=end

module BetterCap
module Parsers
# HTML title parser.
class Htmltitle < Base
  def on_packet( pkt )
    s = pkt.to_s
    if s =~ /(.*)<title>(.*)<\/title>(.*)/im
      title = $2
      StreamLogger.log_raw( pkt, 'HTML TITLE', "#{title}" )
    end
  end
end
end
end
