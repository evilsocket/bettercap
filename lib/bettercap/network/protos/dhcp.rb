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
  # DHCP Options
  :DHCPPad                          => 0,
  :DHCPSubnetMask                   => 1,
  :DHCPTimeOffset                   => 2,
  :DHCPRouter                       => 3,
  :DHCPTimeServer                   => 4,
  :DHCPNameServer                   => 5,
  :DHCPDNS                          => 6,
  :DHCPLogServer                    => 7,
  :DHCPQuoteServer                  => 8,
  :DHCPLPRServer                    => 9,
  :DHCPImpressServer                => 10,
  :DHCPRLServer                     => 11,
  :DHCPHostName                     => 12,
  :DHCPBootFileSize                 => 13,
  :DHCPMeritDumpFile                => 14,
  :DHCPDomainName                   => 15,
  :DHCPSwapServer                   => 16,
  :DHCPRootPath                     => 17,
  :DHCPExtensionsPath               => 18,
  :DHCPIPForwarding                 => 19,
  :DHCPNonLocalRouting              => 20,
  :DHCPPolicyFilter                 => 21,
  :DHCPMaximumDRSize                => 22, # Datagram reassembly size
  :DHCPDefaultIPTTL                 => 23,
  :DHCPPathMTUAgingTimeout          => 24,
  :DHCPPathMTUPlateauTable          => 25,
  :DHCPInterfaceMTU                 => 26,
  :DHCPAllSubnetsLocal              => 27,
  :DHCPBroadcastAddress             => 28,
  :DHCPPerformMask                  => 29, # Perform mask discovery
  :DHCPMaskSupplier                 => 30, # Zelda flashbacks
  :DHCPPerformRouter                => 31, # Perform router discovery
  :DHCPRouterSolicitation           => 32, # Router Solicitation Address
  :DHCPStaticRoutingEnable          => 33,
  :DHCPTrailerEncap                 => 34, # Trailer Encapsulation
  :DHCPArpCacheTimeout              => 35,
  :DHCPEthernetEncap                => 36, # ethernet encapsulation
  :DHCPDefaultTCPTTL                => 37,
  :DHCPTCPKeepAliveInt              => 38, # TCP Keepalive interval
  :DHCPTCPKeepAliveGB               => 39, # TCP Keepalive garbage
  :DHCPNISDomain                    => 40,
  :DHCPNISServer                    => 41,
  :DHCPNTPServers                   => 42,
  :DHCPVendorSpecificInfo           => 43,
  :DHCPNetBIOSNameServer            => 44,
  :DHCPNetBIOSDDS                   => 45,
  :DHCPNetBIOSNodeType              => 46,
  :DHCPNetBIOSScope                 => 47,
  :DHCPXWindowSystemFont            => 48, # XWindow Font server
  :DHCPXWindowSystemDM              => 49, # Xwindow System Display Server
  :DHCPRequestedIPAddress           => 50,
  :DHCPIPAddressLeaseTime           => 51,
  :DHCPOptionOverload               => 52,
  :DHCPMessageType                  => 53,
  :DHCPServerIdentifier             => 54,
  :DHCPParameters                   => 55,
  :DHCPMessage                      => 56,
  :DHCPMaxDHCPMessageSize           => 57,
  :DHCPRenewTimeValue               => 58,
  :DHCPRebindingTimeValue           => 59,
  :DHCPClassIdentifier              => 60,
  :DHCPClientIdentifier             => 61,
  :DHCPNetWareIPDomainName          => 62,
  :DHCPNetWareIPInformation         => 63,
  :DHCPNISClientDomain              => 64,
  :DHCPNISServers                   => 65,
  :DHCPTFTPServerName               => 66,
  :DHCPBootFileName                 => 67,
  :DHCPMobileIPHomeAgent            => 68,
  :DHCPSMTPServer                   => 69,
  :DHCPPOPServer                    => 70,
  :DHCPNNTPServer                   => 71,
  :DHCPDefaultWWWServer             => 72,
  :DHCPDefaultFingerServer          => 73,
  :DHCPDefaultIRCServer             => 74,
  :DHCPStreetTalkServer             => 75,
  :DHCPStreetTalkDAS                => 76,
  :DHCPUserClassInformation         => 77,
  :DHCPSLPDirectoryAgent            => 78,
  :DHCPSLPServiceScope              => 79,
  :DHCPRapidCommit                  => 80,
  :DHCPFQDN                         => 81,
  :DHCPRelayAgentInformation        => 82,
  :DHCPInternetStorageNameService   => 83,
  # ??
  :DHCPNDSServers                   => 85,
  :DHCPNDSTreeName                  => 86,
  :DHCPNDSContext                   => 87,
  :DHCPBCMCSContDomainNameList      => 88,
  :DHCPBCMCSContIPV4AddressList     => 89,
  :DHCPAuthentication               => 90,
  :DHCPClientLastTransactTime       => 91,
  :DHCPAssociatedIP                 => 92,
  :DHCPClientSystemArchType         => 93,
  :DHCPClientNetworkInterfaceIdent  => 94,
  :DHCPLDAP                         => 95,
  # ??
  :DHCPClientMachineIdent           => 97,
  :DHCPOGUA                         => 98,
  # ??
  :DHCPAutonomousSystemNumber       => 109,
  # ??
  :DHCPNetInfoParentServerAddress   => 112,
  :DHCPNetInfoParentServerTag       => 113,
  :DHCPURL                          => 114,
  :DHCPAutoConfigure                => 116,
  :DHCPNameServiceSearch            => 117,
  :DHCPSubnetSelection              => 118,
  :DHCPDNSDomainSearchList          => 119,
  :DHCPSIPServers                   => 120,
  :DHCPClasslessStaticRoute         => 121,
  :DHCPCableLabsClientConfig        => 122,
  :DHCPGeoConf                      => 123,
  # ??
  :DHCPProxyAutoDiscovery           => 252
}

OP_CONSTANTS_REV = {
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

class Packet
  attr_accessor :op
  attr_accessor :htype
  attr_accessor :hlen
  attr_accessor :hops
  attr_accessor :xid
  attr_accessor :secs
  attr_accessor :flags
  attr_accessor :ciaddr
  attr_accessor :yiaddr
  attr_accessor :siaddr
  attr_accessor :giaddr
  attr_accessor :chaddr
  attr_accessor :sname
  attr_accessor :file
  attr_accessor :isdhcp
  attr_accessor :dhcpoptions

  def type
    if @dhcpoptions[0] == OP_CONSTANTS[:DHCPMessageType] and @dhcpoptions[1] == 1
      OP_MESSAGETYPES[ @dhcpoptions[2] ]
    else
      OP_MESSAGETYPES[ @op ]
    end
  end

  def client_identifier
    self.each_option do |opt,data|
      if opt == :ClientIdentifier
        return data.pack('c*')
      end
    end
    nil
  end

  def authentication
    # Thank you Wireshark BOOTP dissector!
    self.each_option do |opt,data|
      if opt == :Authentication
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
    nil
  end

  def each_option
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

      yield( OP_CONSTANTS_REV[opt], data )
    end
  end

  def transaction_id
    sprintf( "0x%X", @xid )
  end

  def self.parse data
    pkt = Packet.new

    begin
      pkt.op          = data[0].ord                   # 8bit
      pkt.htype       = data[1].ord                   # 8bit
      pkt.hlen        = data[2].ord                   # 8bit
      pkt.hops        = data[3].ord                   # 8bit
      pkt.xid         = data[4..7].reverse.unpack('L')[0]     # 32bit
      pkt.secs        = data[8..9].unpack('S')[0]     # 16bit
      pkt.flags       = data[10..11].unpack('S')[0]   # 16bit
      pkt.ciaddr      = data[12..15].bytes            # 32bit (ary)
      pkt.yiaddr      = data[16..19].bytes            # 32bit (ary)
      pkt.siaddr      = data[20..23].bytes            # 32bit (ary)
      pkt.giaddr      = data[24..27].bytes            # 32bit (ary)
      pkt.chaddr      = data[28..43].bytes            # 128bit (ary)
      pkt.sname       = data[44..107]                 # 64bit (str)
      pkt.file        = data[108..235]                # 128bit (str)
      pkt.isdhcp      = data[236..239].unpack('L')[0] # COOKIEZ OMNOMNOM (32bit)
      pkt.dhcpoptions = data[240..data.length].bytes  # DHCP Options (rest)
    rescue
      pkt = nil
    end

    pkt
  end
end

end
end
end
end
