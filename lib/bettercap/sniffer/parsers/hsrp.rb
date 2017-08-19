# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : https://www.evilsocket.net/

HSRP packet and authentication parser:
  Author : Brendan Coles
  Email  : bcoles[at]gmail.com

This project is released under the GPL 3 license.

=end

module BetterCap
module Parsers
#
# HSRP packet and authentication parser.
#
# Supports HSRP version 0
# Supports text authentication
# Supports IPv4
#
# Does not support IPv6
# Does not support MD5 authentication
# Does not support HSRP version 2
#
# References:
# - https://en.wikipedia.org/wiki/Hot_Standby_Router_Protocol
# - https://tools.ietf.org/html/rfc2281#section-5
# - https://www.cisco.com/c/en/us/support/docs/ip/hot-standby-router-protocol-hsrp/9234-hsrpguidetoc.html
# - https://www.cisco.com/c/en/us/td/docs/ios-xml/ios/ipapp_fhrp/configuration/xe-3s/fhp-xe-3s-book/fhp-hsrp-md5.html
#
class Hsrp < Base
  def initialize
    @name = 'HSRP'
  end

  def on_packet( pkt )
    if pkt.respond_to? 'hsrp_version'
      parse_hsrp_packetfu pkt
    elsif is_hsrp? pkt
      parse_hsrp_raw pkt
    end
  rescue
  end

  private

  def parse_hsrp_raw(pkt)
    log = []
    data = pkt.payload.to_s.unpack('H*').first

=begin

Packet format from RFC2281, section 5:

                          1                   2                   3

   0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |   Version     |   Op Code     |     State     |   Hellotime   |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |   Holdtime    |   Priority    |     Group     |   Reserved    |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                      Authentication  Data                     |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                      Authentication  Data                     |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                      Virtual IP Address                       |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

=end

    # data[0...2]      # HSRP version
                       # HSRP versions 0 and 2 both advertise as version 0
    version = data[0...2].to_i(16)

    # This parser supports only HSRP version 0
    return unless version == 0

    # data[2...4]      # Op Code:
                       #  0 - Hello
                       #      Hello messages are sent to indicate that a router is running and
                       #      is capable of becoming the active or standby router.
                       #  1 - Coup
                       #      Coup messages are sent when a router wishes to become the active router.
                       #  2 - Resign
                       #      Resign messages are sent when a router no longer wishes to be the
                       #      active router.
                       #  3 - Advertise
                       #      Passive HSRP Router Advertisements
                       #      This OpCode is not described in RFC2281.
    op_code = data[2...4].to_i(16)
    case op_code
    when 0
      log << 'hello'.yellow
    when 1
      log << 'coup'.yellow
    when 2
      log << 'resign'.yellow
    when 3
      log << 'advertise'.yellow
    else
      log << 'unknown'.yellow
    end

    log << "#{'OpCode'.blue}=#{op_code}"

    # data[4...6]      # State:
                       #         0 - Initial
                       #         1 - Learn
                       #         2 - Listen
                       #         4 - Speak
                       #         8 - Standby
                       #        16 - Active
    state = data[4...6].to_i(16)
    case state
    when 0
      state_desc = 'Initial'
    when 1
      state_desc = 'Learn'
    when 2
      state_desc = 'Listen'
    when 4
      state_desc = 'Speak'
    when 8
      state_desc = 'StandBy'
    when 16
      state_desc = 'Active'
    else
      state_desc = 'Unknown'
    end

    log << "#{'State'.blue}=#{state_desc.yellow} (#{state})"

    # data[6...8]      # HelloTime - Time (in seconds) between Hello messages
    hello_time = data[6...8].to_i(16)
    log << "#{'HelloTime'.blue}=#{hello_time}"

    # data[8...10]     # HoldTime - Time (in seconds) for which the Hello message is valid
    hold_time = data[8...10].to_i(16)
    log << "#{'HoldTime'.blue}=#{hold_time}"

    # data[10...12]    # Priority
    priority = data[10...12].to_i(16)
    log << "#{'Priority'.blue}=#{priority.to_s.yellow}"

    # data[12...14]    # StandBy Group
    group = data[12...14].to_i(16)
    log << "#{'Group'.blue}=#{group.to_s.yellow}"

    # data[14...16]    # Reserved (0x00)

    # data[16...32]    # Authentication data
    auth = data[16...32]
    log << "#{'Authentication'.blue}=#{auth}"

    # strip trailing null bytes from the authentication data
    # and check if the remaining data is ASCII
    auth_ascii = [auth.gsub(/(00)*\z/, '')].pack('H*')
    if auth_ascii == ''
      # null authentication may indicate HSRPv2 MD5 data occurs later in the packet
      # HSRPv2 is not supported by this parser
      if pkt.payload.length > 50
        log << '(null, md5?)'
      else
        log << '(null)'
      end
    elsif auth_ascii =~ /\A[a-zA-Z0-9_\-+\.,"' ]*\z/
      log << "('#{auth_ascii.yellow}')"
    end

    # data[32...40]    # Virtual IP Address
    virtual_ip = data[32...40].scan(/\w{2}/).map{ |c| c.to_i(16).to_s(10) }.join('.')
    log << "#{'VirtualIP'.blue}='#{virtual_ip.yellow}'"

    StreamLogger.log_raw pkt, @name, log.join(' ')
  rescue
  end

  def parse_hsrp_packetfu(pkt)
    log = []

    op_code = pkt.hsrp_opcode
    case op_code
    when 0
      log << 'hello'.yellow
    when 1
      log << 'coup'.yellow
    when 2
      log << 'resign'.yellow
    when 3
      log << 'advertise'.yellow
    else
      log << 'unknown'.yellow
    end

    log << "#{'OpCode'.blue}=#{op_code}"

    state = pkt.hsrp_state
    case state
    when 0
      state_desc = 'Initial'
    when 1
      state_desc = 'Learn'
    when 2
      state_desc = 'Listen'
    when 4
      state_desc = 'Speak'
    when 8
      state_desc = 'StandBy'
    when 16
      state_desc = 'Active'
    else
      state_desc = 'Unknown'
    end

    log << "#{'State'.blue}=#{state_desc.yellow} (#{state})"
    log << "#{'HelloTime'.blue}=#{pkt.hsrp_hellotime}"
    log << "#{'HoldTime'.blue}=#{pkt.hsrp_holdtime}"
    log << "#{'Priority'.blue}=#{pkt.hsrp_priority.to_s.yellow}"
    log << "#{'Group'.blue}=#{pkt.hsrp_group.to_s.yellow}"

    auth = pkt.hsrp_password.unpack('H*').first
    log << "#{'Authentication'.blue}=#{auth}"

    # strip trailing null bytes from the authentication data
    # and check if the remaining data is ASCII
    auth_ascii = [auth.gsub(/(00)*\z/, '')].pack('H*')
    if auth_ascii == ''
      # null authentication may indicate HSRPv2 MD5 data occurs later in the packet
      # HSRPv2 is not supported by this parser
      if pkt.payload.length > 0
        log << '(null, md5?)'
      else
        log << '(null)'
      end
    elsif auth_ascii =~ /\A[a-zA-Z0-9_\-+\.,"' ]*\z/
      log << "('#{auth_ascii.yellow}')"
    end

    virtual_ip = pkt.hsrp_vip.to_s.unpack('H*').first.to_s.scan(/\w{2}/).map{ |c| c.to_i(16).to_s(10) }.join('.')
    log << "#{'VirtualIP'.blue}='#{virtual_ip.yellow}'"

    StreamLogger.log_raw pkt, @name, log.join(' ')
  rescue
  end

  def is_hsrp?(pkt)
    return ( pkt.eth_daddr == '01:00:5e:00:00:02' && \
             pkt.ip_daddr == '224.0.0.2' && \
             pkt.respond_to?('udp_src') && pkt.respond_to?('udp_dst') && \
             ( pkt.udp_src == 1985 || pkt.udp_dst == 1985 ) && \
             pkt.payload.length >= 20 )
  end
end
end
end
