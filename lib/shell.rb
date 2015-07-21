=begin
BETTERCAP
Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/
This project is released under the GPL 3 license.
=end
module Shell
  class << self

    #return the output of command
    def execute(command)
      r=%x(#{command})
      if $? != 0
        raise "Error, executing #{command}"
      end
      return r
    end
    
    def ifconfig(iface)
      # ensure default en language, see https://github.com/evilsocket/bettercap/issues/6
      self.execute( "LANG=en ifconfig #{iface}" )
    end

  end
end
