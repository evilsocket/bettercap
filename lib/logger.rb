=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
module Logger
  class << self
    def error(message)
      puts formatted_message(message, "E").red
    end

    def info(message)
      puts formatted_message(message, "I")
    end

    def debug(message)
      puts formatted_message(message, "D").light_black
    end

    def write(filename,message)
      File.open(filename, "a") { |f| f << message }
    end

    private
    def formatted_message(message, message_type)
      "[#{message_type}] #{message}"
    end
  end
end
