# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : https://www.evilsocket.net/

Open Shortest Path First (OSPF) packet and authentication parser:
  Author : Brendan Coles
  Email  : bcoles[at]gmail.com

This project is released under the GPL 3 license.

=end

module BetterCap
module Parsers
#
# Open Shortest Path First (OSPF) packet and authentication parser.
#
# Supports OSPF version 2
# Supports simple authentication
# Supports crypto authentication (MD5)
# Supports IPv4
#
# Does not support IPv6
# Does not support OSPF version 3
# - https://tools.ietf.org/html/rfc5340
#
# References:
# - https://en.wikipedia.org/wiki/Open_Shortest_Path_First
# - https://wiki.wireshark.org/OSPF
# - https://tools.ietf.org/html/rfc2328#appendix-A.3
#
class Ospf < Base
  def initialize
    @name = 'OSPF'
  end

  def on_packet( pkt )
    return unless is_ospf? pkt

    log = []
    data = pkt.payload.to_s.unpack('H*').first

=begin

Packet format from RFC2328, Appendix A.3:

        0                   1                   2                   3
        0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       |   Version #   |     Type      |         Packet length         |
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       |                          Router ID                            |
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       |                           Area ID                             |
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       |           Checksum            |             AuType            |
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       |                       Authentication                          |
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       |                       Authentication                          |
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

=end

    # data[0...2]      # OSPF version
    version = data[0...2].to_i(16)

    # This parser supports only OSPF version 2
    return unless version == 2

    # data[2...4]      # Type:
                       #  1 - Hello
                       #  2 - Database Description
                       #  3 - Link State Request
                       #  4 - Link State Update
                       #  5 - Link State Acknowledgment
    type = data[2...4].to_i(16)
    case type
    when 1
      log << 'Hello'.yellow
    when 2
      log << 'Database Description'.yellow
    when 3
      log << 'Link State Request'.yellow
    when 4
      log << 'Link State Update'.yellow
    when 5
      log << 'Link State Acknowledgment'.yellow
    else
      log << 'Unknown'.yellow
    end

    log << "#{'Type'.blue}=#{type}"


    # data[4...8]      # Packet Length
                       # Length of the packet (in bytes) including header

    # data[8...16]     # OSPF Router ID
    router_id = data[8...16].scan(/\w{2}/).map{ |c| c.to_i(16).to_s(10) }.join('.')
    log << "#{'RouterID'.blue}='#{router_id.yellow}'"

    # data[16...24]    # Area ID
    area_id = data[16...24].scan(/\w{2}/).map{ |c| c.to_i(16).to_s(10) }.join('.')
    log << "#{'AreaID'.blue}='#{area_id.yellow}'"

    # data[24...28]    # Checksum

    # data[28...32]    # Authentication Type
                       #   0            Null authentication
                       #   1            Simple password
                       #   2            Cryptographic authentication
                       #   All others   Reserved for assignment by the IANA (iana@ISI.EDU)
    auth_type = data[28...32].to_i(16)
    case auth_type
    when 0 # Null Authentication
      log << "#{'AuthType'.blue}=#{'null'.yellow} (#{auth_type})"

    when 1 # Simple password
      log << "#{'AuthType'.blue}=#{'simple'.yellow} (#{auth_type})"

      # data[32...48]  # Authentication Data
      auth_data = data[32...48]
      log << "#{'AuthData'.blue}=#{auth_data}"

      # strip trailing null bytes from the authentication data
      # and check if the remaining data is printable ASCII
      auth_ascii = [auth_data.gsub(/(00)*\z/, '')].pack('H*')
      if auth_ascii =~ /\A[a-zA-Z0-9_\-+\.,"' ]*\z/
        log << "('#{auth_ascii.yellow}')"
      end

    when 2 # Cryptographic Authentication
      log << "#{'AuthType'.blue}=#{'crypto'.yellow} (#{auth_type})"

=begin

Cryptographic authentication format from RFC2328, Appendix D:

        0                   1                   2                   3
        0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       |              0                |    Key ID     | Auth Data Len |
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       |                 Cryptographic sequence number                 |
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
=end

      # data[32...36]  # Checksum - '\x00\x00' for crypto authentication

      # data[36...38]  # Auth Key
      auth_key = data[36...38].to_i(16)
      log << "#{'AuthKey'.blue}=#{auth_key}"

      # data[38...40]  # Auth Data Length - length (in bytes) of the message digest
                       # that will be appended to the OSPF packet.
      auth_len = data[38...40].to_i(16)

      # data[40...48]  # 32-bit Cryptographic sequence number
      auth_seq = data[40...48].to_i(16)
      log << "#{'AuthSeq'.blue}=#{auth_seq}"

      # data[-auth_len...-1] # Authentication Data
      auth_data = data[(auth_len * 2 * -1)...-1]
      log << "#{'AuthData'.blue}=#{auth_data}"

    else
      log << "#{'AuthType'.blue}=#{'unknown/reserved'.yellow} (#{auth_type})"
    end

    StreamLogger.log_raw pkt, @name, log.join(' ')
  rescue
  end

  def is_ospf?(pkt)
    return ( ( ( pkt.eth_daddr == '01:00:5e:00:00:05' && pkt.ip_daddr == '224.0.0.5' ) || \
               ( pkt.eth_daddr == '01:00:5e:00:00:06' && pkt.ip_daddr == '224.0.0.6' ) ) && \
             pkt.payload.length >= 20 )
  end
end
end
end
