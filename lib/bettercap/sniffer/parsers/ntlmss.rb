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
# NTLMSS authentication parser.
class NTLMSS < Base
  def on_packet( pkt )
    packet = Network::Protos::NTLM::Packet.parse( pkt.payload )
    if !packet.nil? and packet.is_auth?
      msg = "NTLMSSP Authentication:\n"
      msg += "  #{'LM Response'.blue}   : #{packet.lm_response.map { |x| sprintf("%02X", x )}.join.yellow}\n"
      msg += "  #{'NTLM Response'.blue} : #{packet.ntlm_response.map { |x| sprintf("%02X", x )}.join.yellow}\n"
      msg += "  #{'Domain Name'.blue}   : #{packet.domain_name.yellow}\n"
      msg += "  #{'User Name'.blue}     : #{packet.user_name.yellow}\n"
      msg += "  #{'Host Name'.blue}     : #{packet.host_name.yellow}\n"
      msg += "  #{'Session Key'.blue}   : #{packet.session_key_resp.map { |x| sprintf("%02X", x )}.join.yellow}"

      StreamLogger.log_raw( pkt, 'NTLM', msg )
    end
  end
end
end
end
