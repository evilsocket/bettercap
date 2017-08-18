# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : https://www.evilsocket.net/

RADIUS packet and authentication parser:
  Author : Brendan Coles
  Email  : bcoles[at]gmail.com

This project is released under the GPL 3 license.

=end

module BetterCap
module Parsers
#
# RADIUS packet and authentication parser.
#
# Supports RADIUS authentication messages over UDP (ports 1812/udp and 1645/udp)
# Does not support RADIUS over TCP
# Does not support RADIUS accounting messages (ports 1813/udp and 1646/udp)
#
# References:
# - https://en.wikipedia.org/wiki/RADIUS
# - https://tools.ietf.org/html/rfc2865#section-3
# - https://tools.ietf.org/html/rfc2869
# - https://www.iana.org/assignments/radius-types/radius-types.xhtml
# - https://technet.microsoft.com/en-us/library/cc958030.aspx
# - http://www.untruth.org/~josh/security/radius/radius-auth.html
#
class Radius < Base
  def initialize
    @name = 'RADIUS'
  end

  def on_packet( pkt )
    return unless is_radius? pkt

    log = []
    data = pkt.payload.to_s.unpack('H*').first

=begin

Packet format from RFC2865, section 3:

    0                   1                   2                   3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |     Code      |  Identifier   |            Length             |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                                                               |
   |                         Authenticator                         |
   |                                                               |
   |                                                               |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |  Attributes ...
   +-+-+-+-+-+-+-+-+-+-+-+-+-

=end

    # data[0...2]      # RADIUS Codes (decimal):
                       #        1       Access-Request
                       #        2       Access-Accept
                       #        3       Access-Reject
                       #        4       Accounting-Request
                       #        5       Accounting-Response
                       #       11       Access-Challenge
                       #       12       Status-Server (experimental)
                       #       13       Status-Client (experimental)
                       #      255       Reserved

    code = data[0...2].to_i(16)

    # We're only interested in Access requests and responses
    case code
    when 1
      type = 'request'
    when 2
      type = 'accept'
    when 3
      type = 'reject'
    when 11
      type = 'challenge'
    else
      return
    end

    log << "access-#{type}".yellow
    log << "#{'Code'.blue}=#{code}"

    # data[2...4]      # Identifier
    id = data[2...4].to_i(16)
    log << "#{'ID'.blue}=#{id}"

    # data[4...8]      # Length
    length = data[4...8].to_i(16)

    # data[4...36]     # Request/Response Authenticator
    authenticator = data[8...40]
    log << "#{'Authenticator'.blue}=#{authenticator}"


=begin

RADIUS attribute format from RFC2865, section 5:

    0                   1                   2
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
   |     Type      |    Length     |  Value ...
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-

=end

    # Attribute type label lookup table
    # https://www.iana.org/assignments/radius-types/radius-types.xhtml
    attribute_types = [
      [1, 'User-Name'],
      [2, 'User-Password'],
      [3, 'CHAP-Password'],
      [4, 'NAS-IP-Address'],
      [5, 'NAS-Port'],
      [6, 'Service-Type'],
      [7, 'Framed-Protocol'],
      [8, 'Framed-IP-Address'],
      [9, 'Framed-IP-Netmask'],
      [10, 'Framed-Routing'],
      [11, 'Filter-Id'],
      [12, 'Framed-MTU'],
      [13, 'Framed-Compression'],
      [14, 'Login-IP-Host'],
      [15, 'Login-Service'],
      [16, 'Login-TCP-Port'],
      [17, 'Unassigned'],
      [18, 'Reply-Message'],
      [19, 'Callback-Number'],
      [20, 'Callback-Id'],
      #[21, 'Unassigned'],
      [22, 'Framed-Route'],
      [23, 'Framed-IPX-Network'],
      [24, 'State'],
      [25, 'Class'],
      [26, 'Vendor-Specific'],
      [27, 'Session-Timeout'],
      [28, 'Idle-Timeout'],
      [29, 'Termination-Action'],
      [30, 'Called-Station-Id'],
      [31, 'Calling-Station-Id'],
      [32, 'NAS-Identifier'],
      [33, 'Proxy-State'],
      [34, 'Login-LAT-Service'],
      [35, 'Login-LAT-Node'],
      [36, 'Login-LAT-Group'],
      [37, 'Framed-AppleTalk-Link'],
      [38, 'Framed-AppleTalk-Network'],
      [39, 'Framed-AppleTalk-Zone'],
      [40, 'Acct-Status-Type'],
      [41, 'Acct-Delay-Time'],
      [42, 'Acct-Input-Octets'],
      [43, 'Acct-Output-Octets'],
      [44, 'Acct-Session-Id'],
      [45, 'Acct-Authentic'],
      [46, 'Acct-Session-Time'],
      [47, 'Acct-Input-Packets'],
      [48, 'Acct-Output-Packets'],
      [49, 'Acct-Terminate-Cause'],
      [50, 'Acct-Multi-Session-Id'],
      [51, 'Acct-Link-Count'],
      [52, 'Acct-Input-Gigawords'],
      [53, 'Acct-Output-Gigawords'],
      #[54, 'Unassigned'],
      [55, 'Event-Timestamp'],
      [56, 'Egress-VLANID'],
      [57, 'Ingress-Filters'],
      [58, 'Egress-VLAN-Name'],
      [59, 'User-Priority-Table'],
      [60, 'CHAP-Challenge'],
      [61, 'NAS-Port-Type'],
      [62, 'Port-Limit'],
      [63, 'Login-LAT-Port'],
      [64, 'Tunnel-Type'],
      [65, 'Tunnel-Medium-Type'],
      [66, 'Tunnel-Client-Endpoint'],
      [67, 'Tunnel-Server-Endpoint'],
      [68, 'Acct-Tunnel-Connection'],
      [69, 'Tunnel-Password'],
      [70, 'ARAP-Password'],
      [71, 'ARAP-Features'],
      [72, 'ARAP-Zone-Access'],
      [73, 'ARAP-Security'],
      [74, 'ARAP-Security-Data'],
      [75, 'Password-Retry'],
      [76, 'Prompt'],
      [77, 'Connect-Info'],
      [78, 'Configuration-Token'],
      [79, 'EAP-Message'],
      [80, 'Message-Authenticator'],
      [81, 'Tunnel-Private-Group-ID'],
      [82, 'Tunnel-Assignment-ID'],
      [83, 'Tunnel-Preference'],
      [84, 'ARAP-Challenge-Response'],
      [85, 'Acct-Interim-Interval'],
      [86, 'Acct-Tunnel-Packets-Lost'],
      [87, 'NAS-Port-Id'],
      [88, 'Framed-Pool'],
      [89, 'CUI'],
      [90, 'Tunnel-Client-Auth-ID'],
      [91, 'Tunnel-Server-Auth-ID'],
      [92, 'NAS-Filter-Rule'],
      #[93, 'Unassigned'],
      [94, 'Originating-Line-Info'],
      [95, 'NAS-IPv6-Address'],
      [96, 'Framed-Interface-Id'],
      [97, 'Framed-IPv6-Prefix'],
      [98, 'Login-IPv6-Host'],
      [99, 'Framed-IPv6-Route'],
      [100, 'Framed-IPv6-Pool'],
      [101, 'Error-Cause Attribute'],
      [102, 'EAP-Key-Name'],
      [103, 'Digest-Response'],
      [104, 'Digest-Realm'],
      [105, 'Digest-Nonce'],
      [106, 'Digest-Response-Auth'],
      [107, 'Digest-Nextnonce'],
      [108, 'Digest-Method'],
      [109, 'Digest-URI'],
      [110, 'Digest-Qop'],
      [111, 'Digest-Algorithm'],
      [112, 'Digest-Entity-Body-Hash'],
      [113, 'Digest-CNonce'],
      [114, 'Digest-Nonce-Count'],
      [115, 'Digest-Username'],
      [116, 'Digest-Opaque'],
      [117, 'Digest-Auth-Param'],
      [118, 'Digest-AKA-Auts'],
      [119, 'Digest-Domain'],
      [120, 'Digest-Stale'],
      [121, 'Digest-HA1'],
      [122, 'SIP-AOR'],
      [123, 'Delegated-IPv6-Prefix'],
      [124, 'MIP6-Feature-Vector'],
      [125, 'MIP6-Home-Link-Prefix'],
      [126, 'Operator-Name'],
      [127, 'Location-Information'],
      [128, 'Location-Data'],
      [129, 'Basic-Location-Policy-Rules'],
      [130, 'Extended-Location-Policy-Rules'],
      [131, 'Location-Capable'],
      [132, 'Requested-Location-Info'],
      [133, 'Framed-Management-Protocol'],
      [134, 'Management-Transport-Protection'],
      [135, 'Management-Policy-Id'],
      [136, 'Management-Privilege-Level'],
      [137, 'PKM-SS-Cert'],
      [138, 'PKM-CA-Cert'],
      [139, 'PKM-Config-Settings'],
      [140, 'PKM-Cryptosuite-List'],
      [141, 'PKM-SAID'],
      [142, 'PKM-SA-Descriptor'],
      [143, 'PKM-Auth-Key'],
      [144, 'DS-Lite-Tunnel-Name'],
      [145, 'Mobile-Node-Identifier'],
      [146, 'Service-Selection'],
      [147, 'PMIP6-Home-LMA-IPv6-Address'],
      [148, 'PMIP6-Visited-LMA-IPv6-Address'],
      [149, 'PMIP6-Home-LMA-IPv4-Address'],
      [150, 'PMIP6-Visited-LMA-IPv4-Address'],
      [151, 'PMIP6-Home-HN-Prefix'],
      [152, 'PMIP6-Visited-HN-Prefix'],
      [153, 'PMIP6-Home-Interface-ID'],
      [154, 'PMIP6-Visited-Interface-ID'],
      [155, 'PMIP6-Home-IPv4-HoA'],
      [156, 'PMIP6-Visited-IPv4-HoA'],
      [157, 'PMIP6-Home-DHCP4-Server-Address'],
      [158, 'PMIP6-Visited-DHCP4-Server-Address'],
      [159, 'PMIP6-Home-DHCP6-Server-Address'],
      [160, 'PMIP6-Visited-DHCP6-Server-Address'],
      [161, 'PMIP6-Home-IPv4-Gateway'],
      [162, 'PMIP6-Visited-IPv4-Gateway'],
      [163, 'EAP-Lower-Layer'],
      [164, 'GSS-Acceptor-Service-Name'],
      [165, 'GSS-Acceptor-Host-Name'],
      [166, 'GSS-Acceptor-Service-Specifics'],
      [167, 'GSS-Acceptor-Realm-Name'],
      [168, 'Framed-IPv6-Address'],
      [169, 'DNS-Server-IPv6-Address'],
      [170, 'Route-IPv6-Information'],
      [171, 'Delegated-IPv6-Prefix-Pool'],
      [172, 'Stateful-IPv6-Address-Pool'],
      [173, 'IPv6-6rd-Configuration'],
      [174, 'Allowed-Called-Station-Id'],
      [175, 'EAP-Peer-Id'],
      [176, 'EAP-Server-Id'],
      [177, 'Mobility-Domain-Id'],
      [178, 'Preauth-Timeout'],
      [179, 'Network-Id-Name'],
      [180, 'EAPoL-Announcement'],
      [181, 'WLAN-HESSID'],
      [182, 'WLAN-Venue-Info'],
      [183, 'WLAN-Venue-Language'],
      [184, 'WLAN-Venue-Name'],
      [185, 'WLAN-Reason-Code'],
      [186, 'WLAN-Pairwise-Cipher'],
      [187, 'WLAN-Group-Cipher'],
      [188, 'WLAN-AKM-Suite'],
      [189, 'WLAN-Group-Mgmt-Cipher'],
      [190, 'WLAN-RF-Band'],
      #[191, 'Unassigned'],
      #[192-223, 'Experimental Use'],
      #[224-240, 'Implementation Specific'],
      #[241, 'Extended-Attribute-1'],
      #[241.1, 'Frag-Status'],
      #[241.2, 'Proxy-State-Length'],
      #[241.3, 'Response-Length'],
      #[241.4, 'Original-Packet-Code'],
      #[241.5, 'IP-Port-Limit-Info'],
      #[241.6, 'IP-Port-Range'],
      #[241.7, 'IP-Port-Forwarding-Map'],
      #[241.{8-25}, 'Unassigned'],
      #[241.26, 'Extended-Vendor-Specific-1'],
      #[241.{27-240}, 'Unassigned'],
      #[241.{241-255}, 'Reserved'],
      #[242, 'Extended-Attribute-2'],
      #[242.{1-25}, 'Unassigned'],
      #[242.26, 'Extended-Vendor-Specific-2'],
      #[242.{27-240}, 'Unassigned'],
      #[242.{241-255}, 'Reserved'],
      #[243, 'Extended-Attribute-3'],
      #[243.{1-25}, 'Unassigned'],
      #[243.26, 'Extended-Vendor-Specific-3'],
      #[243.{27-240}, 'Unassigned'],
      #[243.{241-255}, 'Reserved'],
      #[244, 'Extended-Attribute-4'],
      #[244.{1-25}, 'Unassigned'],
      #[244.26, 'Extended-Vendor-Specific-4'],
      #[244.{27-240}, 'Unassigned'],
      #[244.{241-255}, 'Reserved'],
      #[245, 'Extended-Attribute-5'],
      #[245.1, 'SAML-Assertion'],
      #[245.2, 'SAML-Protocol'],
      #[245.{3-25}, 'Unassigned'],
      #[245.26, 'Extended-Vendor-Specific-5'],
      #[245.{27-240}, 'Unassigned'],
      #[245.{241-255}, 'Reserved'],
      #[246, 'Extended-Attribute-6'],
      #[246.{1-25}, 'Unassigned'],
      #[246.26, 'Extended-Vendor-Specific-6'],
      #[246.{27-240}, 'Unassigned'],
      #[246.{241-255}, 'Reserved'],
      #[247-255, 'Reserved']
    ]

    # data[40..-1] # RADIUS Attributes
    attributes = data[40..(length * 2)]

    attributes_hash = []
    start = 0
    while start < attributes.length
      # attributes[0...2]  # Attribute type
      att_type = attributes[start...(start + 2)].to_i(16)

      # attributes[2...4]  # Attribute length (including type, length and value fields)
      att_length = attributes[(start + 2)...(start + 4)].to_i(16)

      # Break if attribute is malformed
      break if att_length == 0

      # attributes[4...??] # Attribute value
      att_value = attributes[(start + 4)...(start + (att_length * 2))]

      attributes_hash << [att_type, att_value]
      start = start + (att_length * 2)
    end

    attributes_hash.each do |type,value|
      # Lookup attribute label
      att_label = attribute_types.select {|id,name| id == type}.flatten[1].to_s
      att_label = "(#{type})" if att_label == ''

      # Display printable ASCII, where possible
      if [value].pack('H*').to_s =~ /\A[a-zA-Z0-9_\-+\.,"' ]*\z/
        log << "#{att_label.blue}='#{[value].pack('H*').yellow}'"
      # Convert values containing IPv4 addresses to dotted decimal
      elsif value.length == 8 && att_label =~ /IP/
        ip = value.scan(/\w{2}/).map{ |c| c.to_i(16).to_s(10) }.join('.')
        log << "#{att_label.blue}='#{ip.yellow}'"
      else
        log << "#{att_label.blue}=#{value}"
      end
    end

    StreamLogger.log_raw pkt, @name, log.join(' ')
  rescue
  end

  private

  def is_radius?(pkt)
    return ( pkt.respond_to?('udp_src') && pkt.respond_to?('udp_dst') && \
             ( pkt.udp_src == 1812 || pkt.udp_dst == 1812 || \
               pkt.udp_src == 1645 || pkt.udp_dst == 1645 ) && \
             pkt.payload.length >= 20 )
  end
end
end
end
