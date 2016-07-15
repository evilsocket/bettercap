# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

# Monkey patching to remove Internals::Logger.crash calls.
module Celluloid
class Actor
  # Handle any exceptions that occur within a running actor
  def handle_crash(exception)
    shutdown ExitEvent.new(behavior_proxy, exception)
  rescue
  end
end
end
