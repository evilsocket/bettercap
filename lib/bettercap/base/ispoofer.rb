=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
module BetterCap
class ISpoofer
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
    raise NotImplementedError, 'ISpoofer: Unimplemented method!'
  end
end
end
