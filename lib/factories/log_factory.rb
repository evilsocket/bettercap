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
      puts formatted_message(message, "ERROR")
    end

    def info(message)
      puts << formatted_message(message, "INFO")
    end

    def write(filename,message)
      File.open(filename, "a") { |f| f << message }
    end

    private
    def formatted_message(message, message_type)
      "#{message_type}: #{message}\n"
    end
  end
end
