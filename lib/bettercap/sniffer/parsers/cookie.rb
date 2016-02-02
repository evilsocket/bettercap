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
# HTTP cookies parser.
class Cookie < Base
  # Cookies to ignore.
  FILTER = [ '__cfduid', '_ga', '_gat' ].freeze

  def on_packet( pkt )
    hostname = nil
    cookies = {}

    pkt.to_s.split("\n").each do |line|
      if line =~ /Host:\s*([^\s]+)/i
        hostname = $1
      elsif line =~ /.*Cookie:\s*(.+)/i
        $1.strip.split(';').each do |v|
          k, v = v.split('=').map(&:strip)
          next if k.nil? or v.nil?
          unless k.empty? or v.empty? or FILTER.include?(k)
            cookies[k] = v
          end
        end
      end
    end

    unless hostname.nil? or cookies.empty?
      StreamLogger.log_raw( pkt, "COOKIE", "[#{hostname.yellow}] #{cookies.map{|k,v| "#{k.green}=#{v.yellow}"}.join('; ')}" )
    end
  end
end
end
end
