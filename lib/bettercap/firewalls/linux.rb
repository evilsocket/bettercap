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
  # If +enabled+ is true will enable packet forwarding, otherwise it will
  # disable it.
  def enable_forwarding(enabled)
    Shell.execute("echo #{enabled ? 1 : 0} > /proc/sys/net/ipv4/ip_forward")
  end

  # Return true if packet forwarding is currently enabled, otherwise false.
  def forwarding_enabled?
    Shell.execute('cat /proc/sys/net/ipv4/ip_forward').strip == '1'
  end

  # If +enabled+ is true will enable packet icmp_echo_ignore_broadcasts, otherwise it will
  # disable it.
  def enable_icmp_bcast(enabled)
    Shell.execute("echo #{enabled ? 0 : 1} > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts")
  end

  # If +enabled+ is true will enable send_redirects, otherwise it will
  # disable it.
  def enable_send_redirects(enabled)
    Shell.execute("echo #{enabled ? 0 : 1} > /proc/sys/net/ipv4/conf/all/send_redirects")
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
