=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require 'logger'

class LogFactory
  @@instance = nil

  def LogFactory.get()
    return @@instance unless @@instance.nil?

    @@instance = Logger.new(STDOUT)
  end
end
