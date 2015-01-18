=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require_relative '../base/ifirewall'

class OSXFirewall < IFirewall
  def enable_forwarding(enabled)
    if enabled then
      `sysctl -w net.inet.ip.forwarding=1`
    else
      `sysctl -w net.inet.ip.forwarding=0`
    end
  end

  def forwarding_enabled?()
    `sysctl net.inet.ip.forwarding`.strip.split(' ')[1] == "1"
  end
end
