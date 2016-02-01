=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

module BetterCap
module Parsers
# BSD rlogin authentication parser.
class Rlogin < Base
  def initialize
    @name = 'RLOGIN'
  end
  def on_packet( pkt )
    begin
      if pkt.tcp_dst == 513
        # rlogin packet data = 0x00[client-username]0x00<server-username>0x00<terminal/speed>0x00

        # if client username, server username and terminal/speed were supplied...
        # regex starts at client username as the first null byte is stripped from pkt.payload.to_s
        if pkt.payload.to_s =~ /\A([a-z0-9_-]+)\x00([a-z0-9_-]+)\x00([a-z0-9_-]+\/[0-9]+)\x00\Z/i
          client_user = $1
          server_user = $2
          terminal = $3
          StreamLogger.log_raw( pkt, @name, "client-username=#{client_user} server-username=#{server_user} terminal=#{terminal}" )
        # else, if only server username and terminal/speed were supplied...
        # regex starts at 0x00 as the first null byte is stripped from pkt.payload.to_s and the client username is empty
        elsif pkt.payload.to_s =~ /\A\x00([a-z0-9_-]+)\x00([a-z0-9_-]+\/[0-9]+)\x00\Z/i
          server_user = $1
          terminal = $2
          StreamLogger.log_raw( pkt, @name, "server-username=#{server_user} terminal=#{terminal}" )
        end
      end
    rescue
    end
  end
end
end
end
