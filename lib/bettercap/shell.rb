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
# Class responsible of executing various shell commands.
module Shell
  class << self
    # Execute +command+ and return its output.
    # Raise +BetterCap::Error+ if the return code is not 0.
    def execute(command)
      r = ''
      10.times do
        begin
          r=%x(#{command})
          if $? != 0
            raise BetterCap::Error, "Error, executing #{command}"
          end
          break
        rescue Errno::EMFILE => e
          Logger.debug "Retrying command '#{command}' due to Errno::EMFILE error ..."
          sleep 1
        end
      end
      r
    end

    # Get the +iface+ network interface configuration.
    def ifconfig(iface = '')
      self.execute( "LANG=en && ifconfig #{iface}" )
    end

    # Get the ARP table cached on this computer.
    def arp
      self.execute( 'LANG=en && arp -a -n' )
    end
  end
end
end
