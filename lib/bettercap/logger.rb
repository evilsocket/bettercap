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
  L_RAW = 0
  L_DBG = 1
  L_INF = 2
  L_WRN = 3
  L_ERR = 4

  class Entry
    def initialize( ts, level, message )
      @timestamp = ts
      @level = level
      @message = message
    end

    def create
      case @level
        when Logger::L_RAW
          formatted_message( @message, nil )
        when Logger::L_DBG
          formatted_message( @message, 'D' ).light_black
        when Logger::L_INF
          formatted_message( @message, 'I' )
        when Logger::L_WRN
          formatted_message( @message, 'W' ).yellow
        when Logger::L_ERR
          formatted_message( @message, 'E' ).red
      end
    end

    private

    # Format +message+ for the given +message_type+.
    def formatted_message(message, message_type)
      # raw message?
      if message_type.nil?
        if @timestamp and !message.strip.empty?
          "[#{Time.now}] #{message}"
        else
          message
        end
      elsif @timestamp
        "[#{Time.now}] [#{message_type}] #{message}"
      else
        "[#{message_type}] #{message}"
      end
    end
  end

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

      self.debug(msg)
    end

    # Log an error +message+.
    def error(message)
      @@queue.push Logger::Entry.new( @@timestamp, Logger::L_ERR, message )
    end

    # Log an information +message+.
    def info(message)
      @@queue.push( Logger::Entry.new( @@timestamp, Logger::L_INF, message ) ) unless @silent
    end

    # Log a warning +message+.
    def warn(message)
      @@queue.push Logger::Entry.new( @@timestamp, Logger::L_WRN, message )
    end

    # Log a debug +message+.
    def debug(message)
      if @@debug and not @@silent
        @@queue.push Logger::Entry.new( @@timestamp, Logger::L_DBG, message )
      end
    end

    # Log a +message+ as it is.
    def raw(message)
      @@queue.push( Logger::Entry.new( @@timestamp, Logger::L_RAW, message ) ) unless @silent
    end

    # Wait for the messages queue to be empty.
    def wait!
      while not @@queue.empty?
        msg = @@queue.pop(true) rescue nil
        if msg
          emit msg.create
        end

        sleep(0.3) if msg.nil?
      end
    end

    private

    # Main logger logic.
    def worker
      loop do
        msg = @@queue.pop(true) rescue nil
        if msg and ( @@ctx.nil? or @@ctx.running )
          begin
            emit msg.create
          rescue Exception => e
            Logger.exception e
          end
        end

        sleep(0.3) if msg.nil?
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
  end
end
end
