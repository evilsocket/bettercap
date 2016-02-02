# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require 'bettercap/logger'

module BetterCap
# Raw or http streams pretty logging.
class StreamLogger
  @@MAX_REQ_SIZE = 50

  @@CODE_COLORS  = {
    '2' => :green,
    '3' => :light_black,
    '4' => :yellow,
    '5' => :red
  }

  # Search for the +addr+ IP address inside the list of collected targets and return
  # its compact string representation ( @see BetterCap::Target#to_s_compact ).
  def self.addr2s( addr )
    ctx = Context.get

    return 'local' if addr == ctx.ifconfig[:ip_saddr]

    target = ctx.find_target addr, nil
    return target.to_s_compact unless target.nil?

    addr
  end

  # Log a raw packet ( +pkt+ ) data +payload+ using the specified +label+.
  def self.log_raw( pkt, label, payload )
    nl    = if label.include?"\n" then "\n" else " " end
    label = label.strip
    Logger.raw( "[#{self.addr2s(pkt.ip_saddr)} > #{self.addr2s(pkt.ip_daddr)}#{pkt.respond_to?('tcp_dst') ? ':' + pkt.tcp_dst.to_s : ''}] " \
               "[#{label.green}]#{nl}#{payload.strip}" )
  end

  # Log a HTTP ( HTTPS if +is_https+ is true ) stream performed by the +client+
  # with the +request+ and +response+ most important informations.
  def self.log_http( request, response )
    is_https   = request.port == 443
    request_s  = "#{is_https ? 'https' : 'http'}://#{request.host}#{request.url}"
    response_s = "( #{response.content_type} )"
    request_s  = request_s.slice(0..@@MAX_REQ_SIZE) + '...' unless request_s.length <= @@MAX_REQ_SIZE
    code       = response.code[0]

    if @@CODE_COLORS.has_key? code
      response_s += " [#{response.code}]".send( @@CODE_COLORS[ code ] )
    else
      response_s += " [#{response.code}]"
    end

    Logger.raw "[#{self.addr2s(request.client)}] #{request.verb.light_blue} #{request_s} #{response_s}"
  end
end
end
