# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

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
          when /inet6 [a-z]+:[\s]*([0-9a-fA-F:\x2f]+)/
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
end
