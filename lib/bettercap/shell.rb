=begin
BETTERCAP
Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/
This project is released under the GPL 3 license.
=end
require 'bettercap/error'

module Shell
  class << self

    #return the output of command
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

    def ifconfig(iface = '')
      self.execute( "LANG=en && ifconfig #{iface}" )
    end

    def arp
      self.execute( 'LANG=en && arp -a -n' )
    end

  end
end
