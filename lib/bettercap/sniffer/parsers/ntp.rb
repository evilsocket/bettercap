# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : https://www.evilsocket.net/

NTP packet and authentication parser:
  Author : Brendan Coles
  Email  : bcoles[at]gmail.com

This project is released under the GPL 3 license.

=end

module BetterCap
module Parsers
#
# NTP packet and authentication parser.
#
# Supports NTP version 4
# Supports IPv4
# Supports MD5 authentication
#
# Does not support IPv6
# Does not support NTP version 3
# Does not support SHA1 authentication
#
# References:
# - https://en.wikipedia.org/wiki/Network_Time_Protocol
# - https://wiki.wireshark.org/NTP
# - https://tools.ietf.org/html/rfc1305
# - https://tools.ietf.org/html/rfc5905
# - https://tools.ietf.org/html/rfc7822
#
class Ntp < Base
  def initialize
    @name = 'NTP'
  end

  def on_packet( pkt )
    # We're only interested in NTP packets with MD5 authentication data
    return unless ( pkt.respond_to?('udp_src') && pkt.respond_to?('udp_dst') && \
                    ( pkt.udp_src == 123 || pkt.udp_dst == 123 ) && \
                    pkt.payload.length == 68 )

    log = []
    data = pkt.payload.to_s.unpack('H*').first

=begin

Packet format from RFC5905, section 7.3:

       0                   1                   2                   3
       0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |LI | VN  |Mode |    Stratum     |     Poll      |  Precision   |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                         Root Delay                            |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                         Root Dispersion                       |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                          Reference ID                         |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                                                               |
      +                     Reference Timestamp (64)                  +
      |                                                               |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                                                               |
      +                      Origin Timestamp (64)                    +
      |                                                               |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                                                               |
      +                      Receive Timestamp (64)                   +
      |                                                               |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                                                               |
      +                      Transmit Timestamp (64)                  +
      |                                                               |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                                                               |
      .                                                               .
      .                    Extension Field 1 (variable)               .
      .                                                               .
      |                                                               |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                                                               |
      .                                                               .
      .                    Extension Field 2 (variable)               .
      .                                                               .
      |                                                               |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                          Key Identifier                       |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                                                               |
      |                            dgst (128)                         |
      |                                                               |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

=end

    # NTP packet headers, excluding key ID and key digest
    salt = data[0...-40]
    log << "#{'Salt'.blue}=#{salt}"

    # Key ID
    key_id = data[-40...-32].to_i(16)
    log << " #{'KeyID'.blue}=#{key_id}"

    # MD5 digest
    key = data[-32..-1]
    log << "#{'Digest'.blue}=#{key}"

    # Check for weak passwords
    # Note: Uncomment to enable cracking of weak passwords.
    #       Note that this could cause performance issues.
=begin
    ['secret', 'password', '123456', 'ntp', 'ntp123', 'ntp1234', 'ntp12345', 'foobar'].each do |password|
      md5 = Digest::MD5.new
      md5.update "#{password}#{[salt].pack('H*')}"

      if md5.hexdigest.to_s == key
        log << "('#{password.yellow}')"
        break
      end
    end
=end

    StreamLogger.log_raw pkt, @name, log.join(' ')
  rescue
  end
end
end
end
