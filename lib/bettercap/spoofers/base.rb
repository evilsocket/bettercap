=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
module BetterCap
module Spoofers
class Base
  def initialize
    not_implemented_method!
  end

  def start
    not_implemented_method!
  end

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
