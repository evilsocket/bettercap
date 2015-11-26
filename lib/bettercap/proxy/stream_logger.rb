=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require 'bettercap/logger'

module Proxy
class StreamLogger
  def self.log( is_https, client, request, response )
    client_s   = "[#{client}]"
    verb_s     = request.verb
    request_s  = "#{is_https ? 'https' : 'http'}://#{request.host}#{request.url}"
    response_s = "( #{response.content_type} )"
    request_s  = request_s.slice(0..50) + '...' unless request_s.length <= 50

    verb_s = verb_s.light_blue

    if response.code[0] == '2'
      response_s += " [#{response.code}]".green
    elsif response.code[0] == '3'
      response_s += " [#{response.code}]".light_black
    elsif response.code[0] == '4'
      response_s += " [#{response.code}]".yellow
    elsif response.code[0] == '5'
      response_s += " [#{response.code}]".red
    else
      response_s += " [#{response.code}]"
    end

    Logger.write "#{client_s} #{verb_s} #{request_s} #{response_s}"
  end
end
end

