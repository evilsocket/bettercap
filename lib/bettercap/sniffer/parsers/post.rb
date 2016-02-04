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
# HTTP POST requests parser.
class Post < Base
  def on_packet( pkt )
    s = pkt.to_s
    if s =~ /POST\s+[^\s]+\s+HTTP.+/
      begin
        req = BetterCap::Proxy::Request.parse(pkt.payload)
        # the packet could be incomplete
        unless req.body.nil? or req.body.empty?
          msg = "\n[#{'HEADERS'.green}]\n\n"
          req.headers.each do |name,value|
            msg << "  #{name.blue} : #{value.yellow}\n"
          end
          msg << "\n[#{'BODY'.green}]\n\n"

          req.body.split('&').each do |v|
            name, value = v.split('=')
            msg << "  #{name.blue} : #{URI.unescape(value).yellow}\n"
          end

          StreamLogger.log_raw( pkt, "POST", req.to_url(1000) )
          Logger.raw "#{msg}\n"
        end
      rescue; end
    end
  end
end
end
end
