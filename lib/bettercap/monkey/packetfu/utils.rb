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
require 'bettercap/logger'

module PacketFu
  class Utils
    def self.ifconfig(iface='eth0')
      ret = {}
      iface = iface.to_s.scan(/[0-9A-Za-z]/).join

      Logger.debug "ifconfig #{iface}"

      ifconfig_data = Shell.ifconfig(iface)
      if ifconfig_data =~ /#{iface}/i
        ifconfig_data = ifconfig_data.split(/[\s]*\n[\s]*/)
      else
        raise ArgumentError, "Cannot ifconfig #{iface}"
      end

      case RUBY_PLATFORM
      when /linux/i
        ret = linux_ifconfig iface, ifconfig_data
      when /darwin/i
        ret = darwin_ifconfig iface, ifconfig_data
      end

      ret
    end

    private

    def self.linux_ifconfig(iface='eth0',ifconfig_data)
      Logger.debug "Linux ifconfig #{iface}:\n#{ifconfig_data}"

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
          ret[:ip6_saddr] = $1
          ret[:ip6_obj] = IPAddr.new($1)
        when /ether[\s]+([0-9a-fA-F:]{17})/i
          ret[:eth_saddr] = $1.downcase
          ret[:eth_src] = EthHeader.mac2str(ret[:eth_saddr])
        end
      end

      ret
    end

    def self.darwin_ifconfig(iface='eth0',ifconfig_data)
      Logger.debug "OSX ifconfig #{iface}:\n#{ifconfig_data}"

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
  end
end
