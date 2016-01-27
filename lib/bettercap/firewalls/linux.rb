# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require 'bettercap/firewalls/base'
require 'bettercap/shell'

module BetterCap
module Firewalls
# Linux firewall class.
class Linux < Base

  IPV4_PATH = "/proc/sys/net/ipv4"
  IP_FORWARD_PATH = IPV4_PATH + "/ip_forward"
  ICMP_BCAST_PATH = IPV4_PATH + "/icmp_echo_ignore_broadcasts"
  SEND_REDIRECTS_PATH = IPV4_PATH + "/conf/all/send_redirects"
  # If +enabled+ is true will enable packet forwarding, otherwise it will
  # disable it.
  def enable_forwarding(enabled)
    File.open(IP_FORWARD_PATH,'w') { |f| f.puts "#{enabled ? 1 : 0}" }
  end

  # Return true if packet forwarding is currently enabled, otherwise false.
  def forwarding_enabled?
    File.open(IP_FORWARD_PATH) { |f| f.read.strip == '1' }
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
  def add_port_redirection( r )
    # post route
    Shell.execute('iptables -t nat -I POSTROUTING -s 0/0 -j MASQUERADE')
    # accept all
    Shell.execute('iptables -P FORWARD ACCEPT')
    # add redirection
    Shell.execute("iptables -t nat -A PREROUTING -i #{r.interface} -p #{r.protocol} --dport #{r.src_port} -j DNAT --to #{r.dst_address}:#{r.dst_port}")
  end

  # Remove the +r+ BetterCap::Firewalls::Redirection port redirection object.
  def del_port_redirection( r )
    # remove post route
    Shell.execute('iptables -t nat -D POSTROUTING -s 0/0 -j MASQUERADE')
    # remove redirection
    Shell.execute("iptables -t nat -D PREROUTING -i #{r.interface} -p #{r.protocol} --dport #{r.src_port} -j DNAT --to #{r.dst_address}:#{r.dst_port}")
  end
end
end
end
