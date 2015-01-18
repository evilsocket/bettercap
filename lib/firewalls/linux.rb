=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require_relative '../base/ifirewall'

class LinuxFirewall < IFirewall
  def enable_forwarding(enabled)
    if enabled then
      `echo 1 > /proc/sys/net/ipv4/ip_forward`
    else
      `echo 0 > /proc/sys/net/ipv4/ip_forward`
    end
  end

  def forwarding_enabled?()
    `cat /proc/sys/net/ipv4/ip_forward`.strip == "1"
  end

  def add_port_redirection( iface, proto, from, addr, to )
    # clear nat
    `iptables -t nat -F`
    # clear
    `iptables -F`
    # post route
    `iptables -t nat -I POSTROUTING -s 0/0 -j MASQUERADE`
    # accept all
    `iptables -P FORWARD ACCEPT`
    # add redirection
    `iptables -t nat -A PREROUTING -i #{iface} -p #{proto} --dport #{from} -j REDIRECT --to #{addr}:#{to}`
  end

  def del_port_redirection( iface, proto, from, addr, to )
    # clear nat
    `iptables -t nat -F`
    # clear
    `iptables -F`
    # remove post route
    `iptables -t nat -D POSTROUTING -s 0/0 -j MASQUERADE`
    # remove redirection
    `iptables -t nat -D PREROUTING -i #{iface} -p #{proto} --dport #{from} -j REDIRECT --to #{addr}:#{to}`
  end
end
