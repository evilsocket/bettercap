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
    Logger.info "[#{'TCP PROXY'.green}] Starting on #{@address}:#{@port} ( -> #{@upstream_address}:#{@upstream_port} ) ..."
    @worker = Thread.new &method(:worker)
  end

  def stop
    Logger.info "Stopping TCP proxy ..."
    ::Proxy.stop
    @worker.join
  end

  private

  def worker
    begin
      up_addr = @upstream_address
      up_port = @upstream_port

      ::Proxy.start(:host => @address, :port => @port) do |conn|
        conn.server :srv, :host => up_addr, :port => up_port

        # modify / process request stream
        conn.on_data do |data|
          ip, port = peer
          Logger.info "[#{'TCP PROXY'.green}] #{ip} -> #{'upstream'.yellow}:#{up_port} ( #{data.bytesize} bytes )"

          BetterCap::Proxy::TCP::Module.on_data( ip, port, data )
        end

        # modify / process response stream
        conn.on_response do |backend, resp|
          ip, port = peer
          Logger.info "[#{'TCP PROXY'.green}] #{'upstream'.yellow}:#{up_port} -> #{ip} ( #{resp.bytesize} bytes )"

          BetterCap::Proxy::TCP::Module.on_response( ip, port, resp )
        end

        # termination logic
        conn.on_finish do |backend, name|
          ip, port = peer
          Logger.info "[#{'TCP PROXY'.green}] #{ip}:#{port} connection closed."

          BetterCap::Proxy::TCP::Module.on_finish( ip, port )
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
