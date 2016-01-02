=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require 'webrick'

require 'bettercap/logger'

module BetterCap
module HTTPD
class Server
  def initialize( port = 8081, path = './' )
    @port = port
    @path = path
    @server = WEBrick::HTTPServer.new(
      Port: @port,
      DocumentRoot: @path,
      Logger: WEBrick::Log.new("/dev/null"),
      AccessLog: []
    )
  end

  def start
    Logger.info "Starting HTTPD on port #{@port} and path #{@path} ..."
    @thread = Thread.new {
      @server.start
    }
  end

  def stop
    Logger.info 'Stopping HTTPD ...'

    @server.stop
    @thread.join
  end
end
end
end
