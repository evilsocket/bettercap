# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

module BetterCap
module Network
module Protos
module DHCP

OP_MESSAGETYPES = {
  # DHCP Message type responses (all len = 1)
  1 => 'DISCOVER',
  2 => 'OFFER',
  3 => 'REQUEST',
  4 => 'DECLINE',
  5 => 'ACK',
  6 => 'NAK',
  7 => 'RELEASE'
}

OP_CONSTANTS = {
  0 => :Pad,
  1 => :SubnetMask,
  2 => :TimeOffset,
  3 => :Router,
  4 => :TimeServer,
  5 => :NameServer,
  6 => :DNS,
  7 => :LogServer,
  8 => :QuoteServer,
  9 => :LPRServer,
  10 => :ImpressServer,
  11 => :RLServer,
  12 => :HostName,
  13 => :BootFileSize,
  14 => :MeritDumpFile,
  15 => :DomainName,
  16 => :SwapServer,
  17 => :RootPath,
  18 => :ExtensionsPath,
  19 => :IPForwarding,
  20 => :NonLocalRouting,
  21 => :PolicyFilter,
  22 => :MaximumDRSize,
  23 => :DefaultIPTTL,
  24 => :PathMTUAgingTimeout,
  25 => :PathMTUPlateauTable,
  26 => :InterfaceMTU,
  27 => :AllSubnetsLocal,
  28 => :BroadcastAddress,
  29 => :PerformMask,
  30 => :MaskSupplier,
  31 => :PerformRouter,
  32 => :RouterSolicitation,
  33 => :StaticRoutingEnable,
  34 => :TrailerEncap,
  35 => :ArpCacheTimeout,
  36 => :EthernetEncap,
  37 => :DefaultTCPTTL,
  38 => :TCPKeepAliveInt,
  39 => :TCPKeepAliveGB,
  40 => :NISDomain,
  41 => :NISServer,
  42 => :NTPServers,
  43 => :VendorSpecificInfo,
  44 => :NetBIOSNameServer,
  45 => :NetBIOSDDS,
  46 => :NetBIOSNodeType,
  47 => :NetBIOSScope,
  48 => :XWindowSystemFont,
  49 => :XWindowSystemDM,
  50 => :RequestedIPAddress,
  51 => :IPAddressLeaseTime,
  52 => :OptionOverload,
  53 => :MessageType,
  54 => :ServerIdentifier,
  55 => :Parameters,
  56 => :Message,
  57 => :MaxDHCPMessageSize,
  58 => :RenewTimeValue,
  59 => :RebindingTimeValue,
  60 => :ClassIdentifier,
  61 => :ClientIdentifier,
  62 => :NetWareIPDomainName,
  63 => :NetWareIPInformation,
  64 => :NISClientDomain,
  65 => :NISServers,
  66 => :TFTPServerName,
  67 => :BootFileName,
  68 => :MobileIPHomeAgent,
  69 => :SMTPServer,
  70 => :POPServer,
  71 => :NNTPServer,
  72 => :DefaultWWWServer,
  73 => :DefaultFingerServer,
  74 => :DefaultIRCServer,
  75 => :StreetTalkServer,
  76 => :StreetTalkDAS,
  77 => :UserClassInformation,
  78 => :SLPDirectoryAgent,
  79 => :SLPServiceScope,
  80 => :RapidCommit,
  81 => :FQDN,
  82 => :RelayAgentInformation,
  83 => :InternetStorageNameService,
  # ??
  85 => :NDSServers,
  86 => :NDSTreeName,
  87 => :NDSContext,
  88 => :BCMCSContDomainNameList,
  89 => :BCMCSContIPV4AddressList,
  90 => :Authentication,
  91 => :ClientLastTransactTime,
  92 => :AssociatedIP,
  93 => :ClientSystemArchType,
  94 => :ClientNetworkInterfaceIdent,
  95 => :LDAP,
  # ??
  97 => :ClientMachineIdent,
  98 => :OGUA,
  # ??
  109 => :AutonomousSystemNumber,
  # ??
  112 => :NetInfoParentServerAddress,
  113 => :NetInfoParentServerTag,
  114 => :URL,
  116 => :AutoConfigure,
  117 => :NameServiceSearch,
  118 => :SubnetSelection,
  119 => :DNSDomainSearchList,
  120 => :SIPServers,
  121 => :ClasslessStaticRoute,
  122 => :CableLabsClientConfig,
  123 => :GeoConf,
  252 => :ProxyAutoDiscovery
}

AUTH_PROTOCOLS = {
  0 => "configuration token",
  1 => "delayed authentication"
}

class Packet < Network::Protos::Base
  uint8     :op
  uint8     :htype
  uint8     :hlen
  uint8     :hops
  uint32rev :xid
  uint16    :secs
  uint16    :flags
  ip        :ciaddr
  ip        :yiaddr
  ip        :siaddr
  ip        :giaddr
  mac       :chaddr, :size => 16
  bytes     :sname, :size => 64
  bytes     :file, :size => 128
  uint32    :isdhcp
  bytes     :dhcpoptions

  def type
    self.each_option( :MessageType ) do |_,data|
      return OP_MESSAGETYPES[ data[0] ]
    end
    OP_MESSAGETYPES[ @op ]
  end

  def client_identifier
    self.each_option( :ClientIdentifier ) do |_,data|
      return data.pack('c*')
    end
  end

  def authentication
    # Thank you Wireshark BOOTP dissector!
    self.each_option( :Authentication ) do |_,data|
      auth = {}

      auth['Protocol'] = AUTH_PROTOCOLS[ data[0] ]

      if data[0] == 1
        auth['Delay Algorithm'] = 'HMAC_MD5'
      end

      auth['Replay Detection Method']    = 'Monotonically-increasing counter'
      auth['RDM Replay Detection Value'] = "0x" + data[3..10].map { |b| sprintf( "%02x", b ) }.join
      auth['Secret ID']                  = "0x" + data[11..14].map { |b| sprintf( "%02x", b ) }.join
      auth['HMAC MD5 Hash']              = data[15..data.size].map { |b| sprintf( "%02X", b ) }.join

      return auth
    end
  end

  def each_option sym = nil
    offset = 0
    limit = self.dhcpoptions.size

    while offset < limit
      opt     = self.dhcpoptions[offset]
      break if opt == 0xFF
      offset += 1
      len     = self.dhcpoptions[offset]
      break if len.nil?
      offset += 1
      data    = self.dhcpoptions[offset..offset+len-1]
      offset += len

      if sym.nil? or OP_CONSTANTS[opt] == sym
        yield( OP_CONSTANTS[opt], data )
      end
    end
  end
end

end
end
end
end
