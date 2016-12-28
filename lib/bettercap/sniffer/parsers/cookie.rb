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
class CookieJar
  def initialize
    @store = {}
  end

  def known_cookie?( from, to, kvals )
    with_session( from, to ) do |session|
      session.each do |kv|
        if kv == kvals
          return true
        end
      end
    end
    false
  end

  def store( from, to, kvals )
    with_session( from, to ) do |session|
      session << kvals
    end
  end

  private

  def with_session( from, to )
    root_key = "#{from}->#{to}"
    # do we know this session?
    unless @store.key?(root_key)
      @store[root_key] = []
    end
    yield @store[root_key]
  end
end

# HTTP cookies parser.
class Cookie < Base
  # Cookies to ignore.
  FILTER = [ '__cfduid', '_ga', '_gat' ].freeze

  def initialize
    @jar = CookieJar.new
  end

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
      unless @jar.known_cookie?( pkt.ip_saddr, hostname, cookies )
        StreamLogger.log_raw( pkt, "COOKIE", "[#{hostname.yellow}] #{cookies.map{|k,v| "#{k.green}=#{v.yellow}"}.join('; ')}" )
        @jar.store( pkt.ip_saddr, hostname, cookies )
      end
    end
  end
end
end
end
