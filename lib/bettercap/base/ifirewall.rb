=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
class IFirewall
  def initialize
    @frwd_initial_state = forwarding_enabled?
  end

  def enable_forwarding(enabled)
    not_implemented_method!
  end

  def forwarding_enabled?
    not_implemented_method!
  end

  def add_port_redirection( iface, proto, from, addr, to )
    not_implemented_method!
  end

  def del_port_redirection( iface, proto, from, addr, to )
    not_implemented_method!
  end

  def restore
    if forwarding_enabled? != @frwd_initial_state
      enable_forwarding @frwd_initial_state
    end
  end

private

  def not_implemented_method!
    raise NotImplementedError, 'IFirewall: Unimplemented method!'
  end
end
