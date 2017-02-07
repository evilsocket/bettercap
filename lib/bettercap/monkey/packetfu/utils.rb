# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : https://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

# PacketFu::Utils.ifconfig is broken under OS X, it does
# not correctly parse the netmask field due to a wrong
# regular expression.
#
# ORIGINAL: https://github.com/packetfu/packetfu/blob/master/lib/packetfu/utils.rb#L204
module PacketFu
  class Packet
    def eth2s(which = :src)
      case which
      when :src
        self.eth_src.bytes.map(&(Proc.new {|x| sprintf('%02X',x) })).join(':')
      when :dst
        self.eth_dst.bytes.map(&(Proc.new {|x| sprintf('%02X',x) })).join(':')
      end
    end
  end

  class Utils
    def self.ifconfig(iface='eth0')
      ret = {}

      BetterCap::Logger.debug "ifconfig #{iface}"

      if BetterCap::Shell.available?('ifconfig')
        BetterCap::Logger.debug "Using ifconfig"

        data = BetterCap::Shell.ifconfig(iface)
        if data =~ /#{iface}/i
          data = data.split(/[\s]*\n[\s]*/)
        else
          raise ArgumentError, "Cannot ifconfig #{iface}"
        end

        case RUBY_PLATFORM
        when /linux/i
          ret = linux_ifconfig iface, data
        when /darwin/i
          ret = darwin_ifconfig iface, data
	      when /.+bsd/i
	        ret = openbsd_ifconfig iface, data
        end
      elsif BetterCap::Shell.available?('ip')
        BetterCap::Logger.debug "Using iproute2"

        data = BetterCap::Shell.ip(iface)
        ret = linux_ip iface, data
      else
        raise BetterCap::Error, 'Unsupported operating system'
      end

      ret
    end

    private

    def self.linux_ip(iface='eth0',data)
      BetterCap::Logger.debug "Linux ip #{iface}:\n#{data}"

      ret = {
        :iface => iface,
        :eth_saddr => nil,
        :eth_src => nil,
        :ip_saddr => nil,
        :ip_src => nil,
        :ip4_obj => nil
      }

      lines = data.split("\n").map(&:strip)

      # search for interface
      lines.each_with_index do |line,i|
        if line =~ /\d+:\s+#{iface}:.+/i
          # start parsing this block
          lines[i..lines.size].each do |line|
            case line
            when /^.+([0-9a-f:]{17})\s+.+[0-9a-f:]{17}$/i
              ret[:eth_saddr] = $1.downcase
              ret[:eth_src] = EthHeader.mac2str(ret[:eth_saddr])
            when /^inet\s+([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)\/(\d+)\s.+([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)\s.+$/i
              addr = $1
              bits = $2

              ret[:ip_saddr] = addr
              ret[:ip_src] = [IPAddr.new(addr).to_i].pack('N')
              ret[:ip4_obj] = IPAddr.new(addr)
              ret[:ip4_obj] = ret[:ip4_obj].mask(bits) if bits
            end
          end
          break
        end
      end

      ret
    end

    def self.linux_ifconfig(iface='eth0',ifconfig_data)
      BetterCap::Logger.debug "Linux ifconfig #{iface}:\n#{ifconfig_data}"

      ret = {}
      real_iface = ifconfig_data.first
      ret[:iface] = real_iface.split.first.downcase.gsub(':','')

      if real_iface =~ /[\s]HWaddr[\s]+([0-9a-fA-F:]{17})/i
        ret[:eth_saddr] = $1.downcase
        ret[:eth_src] = EthHeader.mac2str(ret[:eth_saddr])
      end

      ifconfig_data.each do |s|
        case s
          when /inet [a-z]+:[\s]*([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)(.*[a-z]+:([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+))?/i
            ret[:ip_saddr] = $1
            ret[:ip_src] = [IPAddr.new($1).to_i].pack('N')
            ret[:ip4_obj] = IPAddr.new($1)
            ret[:ip4_obj] = ret[:ip4_obj].mask($3) if $3
          when /inet[\s]+([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)(.*Mask[\s]+([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+))?/i
            ret[:ip_saddr] = $1
            ret[:ip_src] = [IPAddr.new($1).to_i].pack('N')
            ret[:ip4_obj] = IPAddr.new($1)
            ret[:ip4_obj] = ret[:ip4_obj].mask($3) if $3
          when /(fe80[^\/]*)/
            begin
              ret[:ip6_saddr] = $1
              ret[:ip6_obj] = IPAddr.new($1)
            rescue; end
          when /ether[\s]+([0-9a-fA-F:]{17})/i
            ret[:eth_saddr] = $1.downcase
            ret[:eth_src] = EthHeader.mac2str(ret[:eth_saddr])
        end
      end

      ret
    end

    def self.darwin_ifconfig(iface='eth0',ifconfig_data)
      BetterCap::Logger.debug "OSX ifconfig #{iface}:\n#{ifconfig_data}"

      ret = {}
      real_iface = ifconfig_data.first
      ret[:iface] = real_iface.split(':')[0]

      ifconfig_data.each do |s|
        case s
          when /ether[\s]([0-9a-fA-F:]{17})/i
            ret[:eth_saddr] = $1
            ret[:eth_src] = EthHeader.mac2str(ret[:eth_saddr])
          when /inet[\s]*([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)(.*Mask[\s]+(0x[a-f0-9]+))?/i
            imask = 0
            if $3
              imask = $3.to_i(16).to_s(2).count("1")
            end

            ret[:ip_saddr] = $1
            ret[:ip_src] = [IPAddr.new($1).to_i].pack("N")
            ret[:ip4_obj] = IPAddr.new($1)
            ret[:ip4_obj] = ret[:ip4_obj].mask(imask) if imask
          when /inet6[\s]*([0-9a-fA-F:\x2f]+)/
            ret[:ip6_saddr] = $1
            ret[:ip6_obj] = IPAddr.new($1)
        end
      end

      ret
    end

    def self.openbsd_ifconfig(iface='em0',ifconfig_data)
      BetterCap::Logger.debug "OpenBSD ifconfig #{iface}:\n#{ifconfig_data}"

      ret = {}
      real_iface = ifconfig_data.first
      ret[:iface] = real_iface.split(':')[0]

      ifconfig_data.each do |s|
        case s
          when /lladdr[\s]([0-9a-fA-F:]{17})/i
            ret[:eth_saddr] = $1
            ret[:eth_src] = EthHeader.mac2str(ret[:eth_saddr])
          when /inet[\s]*([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)(.*Mask[\s]+(0x[a-f0-9]+))?/i
            imask = 0
            if $3
              imask = $3.to_i(16).to_s(2).count("1")
            end

            ret[:ip_saddr] = $1
            ret[:ip_src] = [IPAddr.new($1).to_i].pack("N")
            ret[:ip4_obj] = IPAddr.new($1)
            ret[:ip4_obj] = ret[:ip4_obj].mask(imask) if imask
          when /inet6[\s]*([0-9a-fA-F:\x2f]+)/
            ret[:ip6_saddr] = $1
            ret[:ip6_obj] = IPAddr.new($1)
        end
      end

      ret
    end

  end

  class NDPHeader < Struct.new(:ndp_type, :ndp_code, :ndp_sum,
                                :ndp_reserved, :ndp_tgt, :ndp_opt_type,
                                :ndp_opt_len, :ndp_lla, :body)
    include StructFu
 
    PROTOCOL_NUMBER = 58
 
    def initialize(args={})
      super(
        Int8.new(args[:ndp_type]),
        Int8.new(args[:ndp_code]),
        Int16.new(args[:ndp_sum]),
        Int32.new(args[:ndp_reserved]),
        AddrIpv6.new.read(args[:ndp_tgt] || ("\x00" * 16)),
        Int8.new(args[:ndp_opt_type]),
        Int8.new(args[:ndp_opt_len]),
        EthMac.new.read(args[:ndp_lla])
      )
    end
 
    # Returns the object in string form.
    def to_s
      self.to_a.map {|x| x.to_s}.join
    end
 
    # Reads a string to populate the object.
    def read(str)
      force_binary(str)
      return self if str.nil?
      self[:ndp_type].read(str[0,1])
      self[:ndp_code].read(str[1,1])
      self[:ndp_sum].read(str[2,2])
      self[:ndp_reserved].read(str[4,4])
      self[:ndp_tgt].read(str[8,16])
      self[:ndp_opt_type].read(str[24,1])
      self[:ndp_opt_len].read(str[25,1])
      self[:ndp_lla].read(str[26,2])
      self
    end

    # Setter for the type.
    def ndp_type=(i); typecast i; end
    # Getter for the type.
    def ndp_type; self[:ndp_type].to_i; end
    # Setter for the code.
    def ndp_code=(i); typecast i; end
    # Getter for the code.
    def ndp_code; self[:ndp_code].to_i; end
    # Setter for the checksum. Note, this is calculated automatically with
    # ndp_calc_sum.
    def ndp_sum=(i); typecast i; end
    # Getter for the checksum.
    def ndp_sum; self[:ndp_sum].to_i; end
    # Setter for the reserved.
    def ndp_reserved=(i); typecast i; end
    # Getter for the reserved.
    def ndp_reserved; self[:ndp_reserved].to_i; end
    # Setter for the target address.
    def ndp_tgt=(i); typecast i; end
    # Getter for the target address.
    def ndp_tgt; self[:ndp_tgt].to_i; end
    # Setter for the options type field.
    def ndp_opt_type=(i); typecast i; end
    # Getter for the options type field.
    def ndp_opt_type; self[:ndp_opt_type].to_i; end
    # Setter for the options length.
    def ndp_opt_len=(i); typecast i; end
    # Getter for the options length.
    def ndp_opt_len; self[:ndp_opt_len].to_i; end
    # Setter for the link local address.
    def ndp_lla=(i); typecast i; end
    # Getter for the link local address.
    def ndp_lla; self[:ndp_lla].to_s; end

    # Get target address in a more readable form.
    def ndp_taddr
        self[:ndp_tgt].to_x
    end

    # Set the target address in a more readable form.
    def ndp_taddr=(str)
        self[:ndp_tgt].read_x(str)
    end

     # Sets the link local address in a more readable way.
    def ndp_lladdr=(mac)
        mac = EthHeader.mac2str(mac)
        self[:ndp_lla].read mac
        self[:ndp_lla]
    end

    # Gets the link local address in a more readable way.
    def ndp_lladdr
        EthHeader.str2mac(self[:ndp_lla].to_s)
    end

    def ndp_sum_readable
      "0x%04x" % ndp_sum
    end

    # Set flag bits (First three are flag bits, the rest are reserved).
    def ndp_set_flags=(bits)
        case bits
        when "000"
            self.ndp_reserved = 0x00000000
        when "001"
            self.ndp_reserved = 0x20000000
        when "010"
            self.ndp_reserved = 0x40000000
        when "011"
            self.ndp_reserved = 0x60000000
        when "100"
            self.ndp_reserved = 0x80000000
        when "101"
            self.ndp_reserved = 0xa0000000
        when "110"
            self.ndp_reserved = 0xc0000000
        when "111"
            self.ndp_reserved = 0xe0000000
        end
    end
 
    alias :ndp_tgt_readable :ndp_taddr
    alias :ndp_lla_readable :ndp_lladdr
 
  end

  module NDPHeaderMixin
    def ndp_type=(v); self.ndp_header.ndp_type= v; end
    def ndp_type; self.ndp_header.ndp_type; end
    def ndp_code=(v); self.ndp_header.ndp_code= v; end
    def ndp_code; self.ndp_header.ndp_code; end
    def ndp_sum=(v); self.ndp_header.ndp_sum= v; end
    def ndp_sum; self.ndp_header.ndp_sum; end
    def ndp_sum_readable; self.ndp_header.ndp_sum_readable; end
    def ndp_reserved=(v); self.ndp_header.ndp_reserved= v; end
    def ndp_reserved; self.ndp_header.ndp_reserved; end
    def ndp_tgt=(v); self.ndp_header.ndp_tgt= v; end
    def ndp_tgt; self.ndp_header.ndp_tgt; end
    def ndp_taddr=(v); self.ndp_header.ndp_taddr= v; end
    def ndp_taddr; self.ndp_header.ndp_taddr; end
    def ndp_tgt_readable; self.ndp_header.ndp_tgt_readable; end
    def ndp_opt_type=(v); self.ndp_header.ndp_opt_type= v; end
    def ndp_opt_type; self.ndp_header.ndp_opt_type; end
    def ndp_opt_len=(v); self.ndp_header.ndp_opt_len=v; end
    def ndp_opt_len;self.ndp_header.ndp_opt_len; end
    def ndp_lla=(v); self.ndp_header.ndp_lla=v; end
    def ndp_lla;self.ndp_header.ndp_lla; end
    def ndp_laddr=(v); self.ndp_header.ndp_laddr= v; end
    def ndp_laddr; self.ndp_header.ndp_laddr; end
    def ndp_lla_readable; self.ndp_header.ndp_lla_readable; end
    def ndp_set_flags=(v); self.ndp_header.ndp_set_flags= v; end
  end


  class NDPPacket < Packet
    include ::PacketFu::EthHeaderMixin
    include ::PacketFu::IPv6HeaderMixin
    include PacketFu::NDPHeaderMixin

    attr_accessor :eth_header, :ipv6_header, :ndp_header

    def initialize(args={})
      @eth_header = EthHeader.new(args).read(args[:eth])
      @ipv6_header = IPv6Header.new(args).read(args[:ipv6])
      @ipv6_header.ipv6_next = PacketFu::NDPHeader::PROTOCOL_NUMBER
      @ndp_header = NDPHeader.new(args).read(args[:ndp])

      @ipv6_header.body = @ndp_header
      @eth_header.body = @ipv6_header

      @headers = [@eth_header, @ipv6_header, @ndp_header]
      super
      ndp_calc_sum
    end

    # Calculates the checksum for the object.
    def ndp_calc_sum
      checksum = 0

      # Compute sum on pseudo-header
      [ipv6_src, ipv6_dst].each do |iaddr|
        8.times { |i| checksum += (iaddr >> (i*16)) & 0xffff }
      end
      checksum += PacketFu::NDPHeader::PROTOCOL_NUMBER
      checksum += ipv6_len
      # Continue with entire ICMPv6 message.
      checksum += (ndp_type.to_i << 8) + ndp_code.to_i
      checksum += ndp_reserved.to_i >> 16
      checksum += ndp_reserved.to_i & 0xffff
      8.times { |i| checksum += (ndp_tgt.to_i >> (i*16)) & 0xffff }
      checksum += (ndp_opt_type.to_i << 8) + ndp_opt_len.to_i

      mac2int = ndp_lla.to_s.unpack('H*').first.to_i(16)
      3.times { |i| checksum += (mac2int >> (i*16)) & 0xffff }

      checksum = checksum % 0xffff
      checksum = 0xffff - checksum
      checksum == 0 ? 0xffff : checksum

    end

    # Recalculates the calculatable fields for NDP.
    def ndp_recalc(arg=:all)
      arg = arg.intern if arg.respond_to? :intern
      case arg
      when :ndp_sum
        self.ndp_sum = ndp_calc_sum
      when :all
        self.ndp_sum = ndp_calc_sum
      else
        raise ArgumentError, "No such field `#{arg}'"
      end
    end

  end

end
