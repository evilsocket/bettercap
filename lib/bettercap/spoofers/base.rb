=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
module BetterCap
module Spoofers
# Base class for BetterCap::Spoofers modules.
class Base
  # Will raise NotImplementedError .
  def initialize
    not_implemented_method!
  end
  # Will raise NotImplementedError .
  def start
    not_implemented_method!
  end
  # Will raise NotImplementedError .
  def stop
    not_implemented_method!
  end

private

  def not_implemented_method!
    raise NotImplementedError, 'Spoofers::Base: Unimplemented method!'
  end
end
end
end
