=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
module BetterCap
module Logger
  class << self
    @@ctx     = nil
    @@queue   = Queue.new
    @@debug   = false
    @@silent  = false
    @@logfile = nil
    @@thread  = nil

    def init( debug, logfile, silent )
      @@debug   = debug
      @@logfile = logfile
      @@thread  = Thread.new { worker }
      @@silent  = silent
      @@ctx     = Context.get
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

    def wait!
      while not @@queue.empty?
        if @@thread.nil?
          emit @@queue.pop
        else
          sleep 0.3
        end
      end
    end

    private

    def worker
      loop do
        message = @@queue.pop
        if @@ctx.nil? or @@ctx.running
          emit message
        end
      end
    end

    def emit(message)
      puts message
      unless @@logfile.nil?
        f = File.open( @@logfile, 'a+t' )
        f.puts( message.gsub( /\e\[(\d+)(;\d+)*m/, '') + "\n")
        f.close
      end
    end

    def formatted_message(message, message_type)
      "[#{message_type}] #{message}"
    end
  end
end
end
