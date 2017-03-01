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
# HTTPS connections parser.
class Https < Base
  @@prev = nil
  @@lock = Mutex.new

  def on_packet( pkt )
    begin
      # poor man's TLS Client Hello with SNI extension parser :P
      if pkt.respond_to?(:tcp_dst) and \
         pkt.payload[0] == "\x16" and \
         pkt.payload[1] == "\x03" and \
         pkt.payload =~ /\x00\x00.{4}\x00.{2}([a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,6})\x00/
        hostname = $1
        if pkt.tcp_dst != 443
          hostname += ":#{pkt.tcp_dst}"
        end

        @@lock.synchronize {
          if @@prev.nil? or @@prev != hostname
            StreamLogger.log_raw( pkt, 'HTTPS', "https://#{hostname}/" )
            @@prev = hostname
          end
        }
      end
    rescue; end
  end

end
end
end
