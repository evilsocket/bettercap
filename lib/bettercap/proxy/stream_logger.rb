=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require 'bettercap/logger'

module BetterCap
module Proxy
class StreamLogger
  @@MAX_REQ_SIZE = 50

  @@CODE_COLORS  = {
    '2' => :green,
    '3' => :light_black,
    '4' => :yellow,
    '5' => :red
  }

  def self.addr2s( addr )
    target = Context.get.find_target addr, nil
    return target.to_s_compact unless target.nil?
    addr
  end

  def self.log( is_https, client, request, response )
    request_s  = "#{is_https ? 'https' : 'http'}://#{request.host}#{request.url}"
    response_s = "( #{response.content_type} )"
    request_s  = request_s.slice(0..@@MAX_REQ_SIZE) + '...' unless request_s.length <= @@MAX_REQ_SIZE
    code       = response.code[0]

    if @@CODE_COLORS.has_key? code
      response_s += " [#{response.code}]".send( @@CODE_COLORS[ code ] )
    else
      response_s += " [#{response.code}]"
    end

    Logger.raw "[#{self.addr2s(client)}] #{request.verb.light_blue} #{request_s} #{response_s}"
  end
end
end
end
