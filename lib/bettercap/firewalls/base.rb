=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
module BetterCap
module Firewalls
# Base class for BetterCap::Firewalls objects.
class Base
  # Initialize the firewall object.
  # Raise NotImplementedError
  def initialize
    @frwd_initial_state = forwarding_enabled?
  end

  # If +enabled+ is true will enable packet forwarding, otherwise it will
  # disable it.
  # Raise NotImplementedError
  def enable_forwarding(enabled)
    not_implemented_method!
  end

  # If +enabled+ is true will enable icmp_echo_ignore_broadcasts, otherwise it will
  # disable it.
  # Raise NotImplementedError
  def enable_icmp_bcast(enabled)
    not_implemented_method!
  end

  # If +enabled+ is true will enable send_redirects, otherwise it will
  # disable it.
  # Raise NotImplementedError
  def enable_send_redirects(enabled)
    not_implemented_method!
  end

  # Return true if packet forwarding is currently enabled, otherwise false.
  # Raise NotImplementedError
  def forwarding_enabled?
    not_implemented_method!
  end

  # Apply the +r+ BetterCap::Firewalls::Redirection port redirection object.
  # Raise NotImplementedError
  def add_port_redirection( r )
    not_implemented_method!
  end

  # Remove the +r+ BetterCap::Firewalls::Redirection port redirection object.
  # Raise NotImplementedError
  def del_port_redirection( r )
    not_implemented_method!
  end

  # Restore the system's original packet forwarding state.
  # Raise NotImplementedError
  def restore
    if forwarding_enabled? != @frwd_initial_state
      enable_forwarding @frwd_initial_state
    end
  end

private

  # Method used to raise NotImplementedError exception.
  def not_implemented_method!
    raise NotImplementedError, 'Firewalls::Base: Unimplemented method!'
  end
end
end
end
