# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : https://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

module BetterCap
module Parsers
# HTTP GET requests parser.
class Url < Base
  def on_packet( pkt )
    s = pkt.to_s
    return unless s =~ /GET\s+([^\s]+)\s+HTTP.+Host:\s+([^\s]+).+/m

    host = $2
    url = $1
    unless url =~ /.+\.(png|jpg|jpeg|bmp|gif|img|ttf|woff|css|js).*/i
      StreamLogger.log_raw( pkt, 'GET', "#{'⚫'.red}http://#{host}#{url}" )
    end
  end
end
end
end
