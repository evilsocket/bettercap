# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : https://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
module BetterCap
# Class responsible for console and file logging.
module Logger
  class << self
    @@ctx       = nil
    @@queue     = Queue.new
    @@debug     = false
    @@timestamp = false
    @@silent    = false
    @@logfile   = nil
    @@thread    = nil

    # Initialize the logging system.
    def init( ctx )
      @@debug     = ctx.options.core.debug
      @@logfile   = ctx.options.core.logfile
      @@silent    = ctx.options.core.silent
      @@timestamp = ctx.options.core.log_timestamp
      @@ctx       = ctx
      @@thread    = Thread.new { worker }
    end

    # Log the exception +e+, if this is a beta version, log it as a warning,
    # otherwise as a debug message.
    def exception(e)
      msg = "Exception : #{e.class}\n" +
            "Message   : #{e.message}\n" +
            "Backtrace :\n\n    #{e.backtrace.join("\n    ")}\n"

      if BetterCap::VERSION.end_with?('b')
        self.warn(msg)
      else
        self.debug(msg)
      end
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
      @@queue.push( formatted_message( message, nil ) ) unless @@silent
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

    # Main logger logic.
    def worker
      loop do
        message = @@queue.pop
        if @@ctx.nil? or @@ctx.running
          begin
            emit message
          rescue Exception => e
            Logger.warn "Logger error: #{e.message}"
            Logger.exception e
          end
        end
      end
    end

    # Emit the +message+.
    def emit(message)
      puts message
      unless @@logfile.nil?
        f = File.open( @@logfile, 'a+t' )
        f.puts( message.gsub( /\e\[(\d+)(;\d+)*m/, '') + "\n")
        f.close
      end
    end

    # Format +message+ for the given +message_type+.
    def formatted_message(message, message_type)
      # raw message?
      if message_type.nil?
        if @@timestamp and !message.strip.empty?
          "[#{Time.now}] #{message}"
        else
          message
        end
      elsif @@timestamp
        "[#{Time.now}] [#{message_type}] #{message}"
      else
        "[#{message_type}] #{message}"
      end
    end
  end
end
end
