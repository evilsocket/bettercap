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
        Logger.error "Error, executing #{command}"
        return "ERROR" #error !!!
      end
      return r
    end

  end
end
