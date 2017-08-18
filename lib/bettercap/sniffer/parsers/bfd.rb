# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : https://www.evilsocket.net/

Bidirectional Forwarding Detection (BFD) packet and authentication parser:
  Author : Brendan Coles
  Email  : bcoles[at]gmail.com

This project is released under the GPL 3 license.

=end

module BetterCap
module Parsers
#
# Bidirectional Forwarding Detection (BFD) packet and authentication parser.
#
# References:
# - https://tools.ietf.org/html/rfc5880#section-4
# - https://en.wikipedia.org/wiki/Bidirectional_Forwarding_Detection
#
class Bfd < Base
  def initialize
    @name = 'BFD'
  end

  def on_packet( pkt )
    return unless (pkt.udp_dst == 3784 && pkt.payload.length > 30)

    # It appears PacketFu drops the first two bits from packet.payload
    # (because they're 00?), so let's insert them for consistency.
    data = '00' + pkt.payload.to_s.unpack('H*').first.to_i(16).to_s(2)

=begin

Packet format from RFC5880, section 4:

  The Mandatory Section of a BFD Control packet has the following
  format:

   0                   1                   2                   3
   0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
  |Vers |  Diag   |Sta|P|F|C|A|D|M|  Detect Mult  |    Length     |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
  |                       My Discriminator                        |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
  |                      Your Discriminator                       |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
  |                    Desired Min TX Interval                    |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
  |                   Required Min RX Interval                    |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
  |                 Required Min Echo RX Interval                 |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

  An optional Authentication Section MAY be present:

   0                   1                   2                   3
   0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
  |   Auth Type   |   Auth Len    |    Authentication Data...     |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

=end

    # Mandatory Section of a BFD Control packet
    # -----------------------------------------
    # data[0..2]     # Protocol version

    # This parser supports only BFD version 1
    return unless data[0..2] == '001'

    # data[3..7]     # Diagnostic Code
    # data[8..9]     # State
    # data[10..15]   # Message Flags
    # - data[10]     # - Poll (P)
    # - data[11]     # - Final (F)
    # - data[12]     # - Control Plane Independent (C)
    # - data[13]     # - Authentication Present (A)
    # - data[14]     # - Demand (D)
    # - data[15]     # - Multipoint (M)

    # We're only interested in packets with authentication present
    return unless data[13] == '1'

    # data[16..23]   # Detection time multiplier
    # data[24..31]   # Length of the BFD Control packet, in bytes.
    # data[32..63]   # My Discriminator
    # data[64..95]   # Your Discriminator
    # data[96..127]  # Desired Min TX Interval
    # data[128..159] # Required Min RX Interval
    # data[160..191] # Required Min Echo RX Interval


=begin

Simple Password Authentication Section Format from RFC5880, section 4.2:

   0                   1                   2                   3
   0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
  |   Auth Type   |   Auth Len    |  Auth Key ID  |  Password...  |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
  |                              ...                              |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

=end

    # Simple Authentication Section
    # -----------------------------
    # data[192..199] # Auth Type
                     #         0 - Reserved
                     #         1 - Simple Password
                     #         2 - Keyed MD5
                     #         3 - Meticulous Keyed MD5
                     #         4 - Keyed SHA1
                     #         5 - Meticulous Keyed SHA1
                     #     6-255 - Reserved for future use
    auth_type = data[192..199].to_i(2)

    # We're only interested in simple authentication
    return unless auth_type == 1

    log = []
    log << "#{'AuthType'.blue}=Simple"

    # data[200..207] # Auth Length - the length (in bytes) of the authentication section, including:
                     #   Auth Type (1 byte)
                     #   Auth Length (1 byte)
                     #   Auth Key ID (1 byte)
    auth_len = data[200..207].to_i(2) - 3 # minus 3 to account for auth headers

    # data[208..215] # Auth Key ID
    auth_key = data[208..215].to_i(2)
    log << "#{'AuthKeyID'.blue}=#{auth_key}"

    # data[216..??]  # Password:
                     #   216 to (216 + auth_len)
    if auth_len <= 0
      log << "#{'Password'.blue}=null"
    else
      password = data[216...( 216 + (auth_len * 8) )]
      password_hex = password.to_i(2).to_s(16)
      password_ascii = [password.to_i(2).to_s(16)].pack('H*')
      log << "#{'Password'.blue}=#{password_hex} ('#{password_ascii.yellow}')"
    end

    StreamLogger.log_raw pkt, @name, log.join(' ')
  rescue
  end
end
end
end
