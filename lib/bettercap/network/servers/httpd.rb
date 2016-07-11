# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

module BetterCap
module Network
module Servers

# Simple HTTP server class used to serve static assets when needed.
class HTTPD
  # Initialize the HTTP server with the specified tcp +port+ using
  # +path+ as the document root.
  def initialize( port = 8081, path = './' )
    @port = port
    @path = path
    @server = WEBrick::HTTPServer.new(
      Port: @port,
      DocumentRoot: @path,
      Logger: WEBrick::Log.new("/dev/null"),
      AccessLog: []
    )
  rescue Errno::EADDRINUSE
    raise BetterCap::Error, "[HTTPD] It looks like there's another process listening on port #{@port}, "\
                            "please chose a different port."
  end

  # Start the server.
  def start
    Logger.info "[#{'HTTPD'.green}] Starting on port #{@port} and path #{@path} ..."
    @thread = Thread.new {
      @server.start
    }
  end

  # Stop the server.
  def stop
    Logger.info 'Stopping HTTPD ...'

    @server.stop
    @thread.join
  end
end

end
end
end
