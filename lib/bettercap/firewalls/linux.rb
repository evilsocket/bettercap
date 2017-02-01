# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : https://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

module BetterCap
module Firewalls
# Linux firewall class.
class Linux < Base

  IPV4_PATH = "/proc/sys/net/ipv4"
  IP_FORWARD_PATH = IPV4_PATH + "/ip_forward"
  ICMP_BCAST_PATH = IPV4_PATH + "/icmp_echo_ignore_broadcasts"
  SEND_REDIRECTS_PATH = IPV4_PATH + "/conf/all/send_redirects"
  IPV6_PATH = "/proc/sys/net/ipv6"
  IPV6_FORWARD_PATH = IPV6_PATH + "/conf/all/forwarding"

  def supported?
    # Avoids stuff like this https://github.com/evilsocket/bettercap/issues/341
    File.file?(IP_FORWARD_PATH)
  end

  # If +enabled+ is true will enable packet forwarding, otherwise it will
  # disable it.
  def enable_ipv6_forwarding(enabled)
    File.open(IPV6_FORWARD_PATH,'w') { |f| f.puts "#{enabled ? 1 : 0}"}
  end

  # If +enabled+ is true will enable packet forwarding, otherwise it will
  # disable it.
  def enable_forwarding(enabled)
    File.open(IP_FORWARD_PATH,'w') { |f| f.puts "#{enabled ? 1 : 0}" }
  end

  # Return true if packet forwarding is currently enabled, otherwise false.
  def forwarding_enabled?
    File.open(IP_FORWARD_PATH) { |f| f.read.strip == '1' }
  end

  # Return true if packet forwarding for IPv6 is currently enabled, otherwise false.
  def ipv6_forwarding_enabled?
    File.open(IPV6_FORWARD_PATH) { |f| f.read.strip == '1' }
  end


  # If +enabled+ is true will enable packet icmp_echo_ignore_broadcasts, otherwise it will
  # disable it.
  def enable_icmp_bcast(enabled)
    File.open(ICMP_BCAST_PATH,'w') { |f| f.puts "#{enabled ? 1 : 0}" }
  end

  # If +enabled+ is true will enable send_redirects, otherwise it will
  # disable it.
  def enable_send_redirects(enabled)
    File.open(SEND_REDIRECTS_PATH,'w') { |f| f.puts "#{enabled ? 1 : 0}" }
  end

  # Apply the +r+ BetterCap::Firewalls::Redirection port redirection object.
  def add_port_redirection( r, use_ipv6 )
    table = 'iptables'
    cal_dst_address = r.dst_address
    if use_ipv6
      table = 'ip6tables'
      # Prevent sending out ICMPv6 Redirect packets.
      Shell.execute("#{table} -I OUTPUT -p icmpv6 --icmpv6-type redirect -j DROP")

      # Ipv6 uses a different ip + port representation
      cal_dst_address = "[#{r.dst_address}]"
    end
    # post route
    Shell.execute("#{table} -t nat -I POSTROUTING -s 0/0 -j MASQUERADE")
    # accept all
    Shell.execute("#{table} -P FORWARD ACCEPT")
    # add redirection
    Shell.execute("#{table} -t nat -A PREROUTING -i #{r.interface} -p #{r.protocol} #{r.src_address.nil? ? '' : "-d #{r.src_address}"} --dport #{r.src_port} -j DNAT --to #{cal_dst_address}:#{r.dst_port}")
  end

  # Remove the +r+ BetterCap::Firewalls::Redirection port redirection object.
  def del_port_redirection( r, use_ipv6 )
    table = 'iptables'
    cal_dst_address = r.dst_address
    if use_ipv6
      table = 'ip6tables'
      # Ipv6 uses a different ip + port representation
      cal_dst_address = "[#{r.dst_address}]"
    end
    # remove post route
    Shell.execute("#{table} -t nat -D POSTROUTING -s 0/0 -j MASQUERADE")
    # remove redirection
    Shell.execute("#{table} -t nat -D PREROUTING -i #{r.interface} -p #{r.protocol} #{r.src_address.nil? ? '' : "-d #{r.src_address}"} --dport #{r.src_port} -j DNAT --to #{cal_dst_address}:#{r.dst_port}")
  end
end
end
end
