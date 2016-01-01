=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
module Logger
  class << self
    def init( debug, logfile, silent )
      @@debug   = debug
      @@logfile = logfile
      @@queue   = Queue.new
      @@thread  = Thread.new { worker }
      @@silent  = silent
    end

    def error(message)
      @@queue.push formatted_message(message, 'E').red
    end

    def info(message)
      @@queue.push( formatted_message(message, 'I') ) unless @@silent
    end

    def warn(message)
      @@queue.push formatted_message(message, 'W').yellow
    end

    def debug(message)
      if @@debug and not @@silent
        @@queue.push formatted_message(message, 'D').light_black
      end
    end

    def raw(message)
      @@queue.push( message )
    end

    private

    def worker
      loop do
        message = @@queue.pop
        puts message
        unless @@logfile.nil?
          f = File.open( @@logfile, 'a+t' )
          f.puts( message.gsub( /\e\[(\d+)(;\d+)*m/, '') + "\n")
          f.close
        end
      end
    end

    def formatted_message(message, message_type)
      "[#{message_type}] #{message}"
    end
  end
end
