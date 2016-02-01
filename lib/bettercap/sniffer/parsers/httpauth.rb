# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require 'base64'

module BetterCap
module Parsers
# HTTP basic and digest authentication parser.
class Httpauth < Base
  def on_packet( pkt )
    lines = pkt.to_s.split("\n")
    hostname = nil
    path = nil

    lines.each do |line|
      if line =~ /[A-Z]+\s+(\/[^\s]+)\s+HTTP\/\d\.\d/
        path = $1

      elsif line =~ /Host:\s*([^\s]+)/i
        hostname = $1

      elsif line =~ /Authorization:\s*Basic\s+([^\s]+)/i
        encoded = $1
        decoded = Base64.decode64(encoded)
        user, pass = decoded.split(':')

        StreamLogger.log_raw( pkt, 'HTTP BASIC AUTH', "http://#{hostname}#{path} - username=#{user} password=#{pass}".yellow )

      elsif line =~ /Authorization:\s*Digest\s+(.+)/i
        StreamLogger.log_raw( pkt, 'HTTP DIGEST AUTH', "http://#{hostname}#{path}\n#{$1}".yellow )
      end
    end
  end
end
end
end
