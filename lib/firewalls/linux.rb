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
end
