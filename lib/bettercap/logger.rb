=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
module BetterCap
# Class responsible for console and file logging.
module Logger
  class << self
    @@ctx     = nil
    @@queue   = Queue.new
    @@debug   = false
    @@silent  = false
    @@logfile = nil
    @@thread  = nil

    # Initialize the logging system.
    # If +debug+ is true, debug logging will be enabled.
    # If +logfile+ is not nil, every message will be saved to that file.
    # If +silent+ is true, all messages will be suppressed if they're not errors
    # or warnings.
    def init( debug, logfile, silent )
      @@debug   = debug
      @@logfile = logfile
      @@thread  = Thread.new { worker }
      @@silent  = silent
      @@ctx     = Context.get
    end

    # Log an error +message+.
    def error(message)
      @@queue.push formatted_message(message, 'E').red
    end

    # Log an information +message+.
    def info(message)
      @@queue.push( formatted_message(message, 'I') ) unless @@silent
    end

    # Log a warning +message+.
    def warn(message)
      @@queue.push formatted_message(message, 'W').yellow
    end

    # Log a debug +message+.
    def debug(message)
      if @@debug and not @@silent
        @@queue.push formatted_message(message, 'D').light_black
      end
    end

    # Log a +message+ as it is.
    def raw(message)
      @@queue.push( message )
    end

    # Wait for the messages queue to be empty.
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
