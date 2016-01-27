# encoding: UTF-8
=begin
BETTERCAP
Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/
This project is released under the GPL 3 license.
=end
require 'bettercap/error'

module BetterCap
# This class is responsible for dynamically loading modules.
class Loader
  # Dynamically load a class given its +name+.
  # @see https://github.com/evilsocket/bettercap/issues/88
  def self.load(name)
    root = Kernel
    name.split('::').each do |part|
      root = root.const_get(part)
    end
    root
  end
end
end
