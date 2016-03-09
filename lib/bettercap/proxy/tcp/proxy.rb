# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

module BetterCap
module Proxy
module TCP

# Transparent TCP proxy class.
class Proxy
  attr_reader :address
  attr_reader :port
  attr_reader :upstream_address
  attr_reader :upstream_port

  def initialize( address, port, up_address, up_port )
    @address          = address
    @port             = port
    @upstream_address = up_address
    @upstream_port    = up_port
    @worker           = nil
  end

  def start
    Logger.info "[#{'TCP'.green}] Proxy starting on #{@address}:#{@port} ( -> #{@upstream_address}:#{@upstream_port} ) ..."
    @worker = Thread.new &method(:worker)
  end

  def stop
    Logger.info "Stopping TCP proxy ..."
    ::Proxy.stop
    @worker.join
  end

  private

  def worker
    Logger.info "[#{'TCP'.green}] Proxy worker thread started."
    begin
      up_addr = @upstream_address
      up_port = @upstream_port

      ::Proxy.start(:host => @address, :port => @port) do |conn|
        conn.server :srv, :host => up_addr, :port => up_port

        # modify / process request stream
        conn.on_data do |data|
          p [:on_data, data]
          data
        end

        # modify / process response stream
        conn.on_response do |backend, resp|
          p [:on_response, backend, resp]
          resp
        end

        # termination logic
        conn.on_finish do |backend, name|
          p [:on_finish, name]
          unbind
        end
      end
    rescue Exception => e
      Logger.error e.message
      Logger.exception e
    end
  end
end

end
end
end
