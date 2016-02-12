# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

SNMP network protos:
  Author : Matteo Cantoni
  Email  : matteo.cantoni@nothink.org

This project is released under the GPL 3 license.

Todo:
  - add SNMPv1 PDU structure
  - add SNMPv2 support

=end

module BetterCap
module Network
module Protos
module SNMP

# https://en.wikipedia.org/wiki/Simple_Network_Management_Protocol
# http://docwiki.cisco.com/wiki/Simple_Network_Management_Protocol
class Packet < Network::Protos::Base

  #0000   30 29 02 01 00 04 06 70 75 62 6c 69 63 a1 1c 02
  #0010   04 36 eb 8d d1 02 01 00 02 01 00 30 0e 30 0c 06
  #0020   08 2b 06 01 02 01 01 01 00 05 00

  uint16  :snmp_asn_decode			                    # 30 29

  uint8   :snmp_version_type			                    # 02 
  uint8   :snmp_version_length			                    # 01 
  uint8   :snmp_version_number			                    # 00

  uint8   :snmp_community_type			                    # 04
  uint8   :snmp_community_length		                    # 06
  bytes   :snmp_community_string,  :size => :snmp_community_length  # 70 75 62 6c 69 63
end

end
end
end
end
