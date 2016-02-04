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
# HTTP GET requests parser.
class Url < Base
  def on_packet( pkt )
    s = pkt.to_s
    if s =~ /GET\s+([^\s]+)\s+HTTP.+Host:\s+([^\s]+).+/m
      host = $2
      url = $1
      if not url =~ /.+\.(png|jpg|jpeg|bmp|gif|img|ttf|woff|css|js).*/i
        StreamLogger.log_raw( pkt, 'GET', "http://#{host}#{url}" )
      end
    end
  end
end
end
end
