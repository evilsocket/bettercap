=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
class IFirewall
  def enable_forwarding(enabled)
    raise "IFirewall: Unimplemented method!"
  end

  def forwarding_enabled?()
    raise "IFirewall: Unimplemented method!"
  end

  def add_port_redirection( iface, proto, from, addr, to )
    raise "IFirewall: Unimplemented method!"
  end

  def del_port_redirection( iface, proto, from, addr, to )
    raise "IFirewall: Unimplemented method!"
  end
end
