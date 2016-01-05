=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require 'bettercap/base/ifirewall'
require 'bettercap/shell'

module BetterCap
module Firewalls
class Linux < IFirewall
  def enable_forwarding(enabled)
    shell.execute("echo #{enabled ? 1 : 0} > /proc/sys/net/ipv4/ip_forward")
  end

  def forwarding_enabled?
    shell.execute('cat /proc/sys/net/ipv4/ip_forward').strip == '1'
  end

  def enable_icmp_bcast(enabled)
    shell.execute("echo #{enabled ? 0 : 1} > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts")
  end

  def add_port_redirection( r )
    # post route
    shell.execute('iptables -t nat -I POSTROUTING -s 0/0 -j MASQUERADE')
    # accept all
    shell.execute('iptables -P FORWARD ACCEPT')
    # add redirection
    shell.execute("iptables -t nat -A PREROUTING -i #{r.interface} -p #{r.protocol} --dport #{r.src_port} -j DNAT --to #{r.dst_address}:#{r.dst_port}")
  end

  def del_port_redirection( r )
    # remove post route
    shell.execute('iptables -t nat -D POSTROUTING -s 0/0 -j MASQUERADE')
    # remove redirection
    shell.execute("iptables -t nat -D PREROUTING -i #{r.interface} -p #{r.protocol} --dport #{r.src_port} -j DNAT --to #{r.dst_address}:#{r.dst_port}")
  end

  private

  def shell
    Shell
  end
end
end
end
