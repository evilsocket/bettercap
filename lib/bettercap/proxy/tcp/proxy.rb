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

# Class used to encapsulate ( and keep references ) of a single TCP event-.
# http://stackoverflow.com/questions/161510/pass-parameter-by-reference-in-ruby
class Event
  # The source IP address of this event.
  attr_accessor :ip
  # Source port.
  attr_accessor :port
  # Reference to the buffer being transmitted.
  attr_accessor :data

  def initialize( ip, port, data = nil )
    @ip   = ip
    @port = port
    @data = data
  end
end

# Transparent TCP proxy class.
class Proxy
  # Initialize the TCP proxy with given arguments.
  def initialize( address, port, up_address, up_port )
    @address          = address
    @port             = port
    @upstream_address = up_address
    @upstream_port    = up_port
    @ctx              = BetterCap::Context.get
    @worker           = nil
  end

  # Start the proxy.
  def start
    Logger.info "[#{'TCP PROXY'.green}] Starting on #{@address}:#{@port} ( -> #{@upstream_address}:#{@upstream_port} ) ..."
    @worker = Thread.new &method(:worker)
    # If the upstream server is in this network, we need to make sure that its MAC
    # address is discovered and put in the ARP cache before we even start the proxy,
    # otherwise internal connections won't be spoofed and the proxy will be useless
    # until some random event will fill the ARP cache for the server.
    if @ctx.iface.network.include?( @upstream_address )
      Logger.debug "[#{'TCP PROXY'.green}] Sending probe to upstream server address ..."
      BetterCap::Network.get_hw_address( @ctx, @upstream_address )
      # wait for the system to acknowledge the ARP cache changes.
      sleep( 1 )
    end
  end

  # Stop the proxy.
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
      up_svc  = BetterCap::StreamLogger.service( :tcp, @upstream_port )

      ::Proxy.start(:host => @address, :port => @port) do |conn|
        conn.server :srv, :host => up_addr, :port => up_port

        # ip -> upstream
        conn.on_data do |data|
          ip, port = peer
          event    = Event.new( ip, port, data )

          Logger.info "[#{'TCP PROXY'.green}] #{ip} #{'->'.green} #{'upstream'.yellow}:#{up_svc} ( #{event.data.bytesize} bytes )"

          Module.dispatch( 'on_data', event )
          event.data
        end

        # upstream -> ip
        conn.on_response do |backend, resp|
          ip, port = peer
          event    = Event.new( ip, port, resp )

          Logger.info "[#{'TCP PROXY'.green}] #{'upstream'.yellow}:#{up_svc} #{'->'.green} #{ip} ( #{event.data.bytesize} bytes )"

          Module.dispatch( 'on_response', event )
          event.data
        end

        # termination
        conn.on_finish do |backend, name|
          ip, port = peer
          event    = Event.new( ip, port )

          Logger.info "[#{'TCP PROXY'.green}] #{ip} <- #{'closed'.red} -> #{'upstream'.yellow}:#{up_svc}"

          Module.dispatch( 'on_finish', event )
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
