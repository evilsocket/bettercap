=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require 'bettercap/sniffer/parsers/base'
require 'colorize'
require 'base64'

class HttpauthParser < BaseParser
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

        Logger.write "[#{pkt.ip_saddr}:#{pkt.tcp_src} > #{pkt.ip_daddr}:#{pkt.tcp_dst} #{pkt.proto.last}] " +
          '[HTTP BASIC AUTH]'.green + " http://#{hostname}#{path} - username=#{user} password=#{pass}".yellow
          
      elsif line =~ /Authorization:\s*Digest\s+(.+)/i
         Logger.write "[#{pkt.ip_saddr}:#{pkt.tcp_src} > #{pkt.ip_daddr}:#{pkt.tcp_dst} #{pkt.proto.last}] " +
          '[HTTP DIGEST AUTH]'.green + " http://#{hostname}#{path}\n#{$1}".yellow

      end
    end
  end
end

