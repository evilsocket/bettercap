# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : https://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

module BetterCap
module Proxy
module UDP


# Class used to encapsulate ( and keep references ) of a single UDP event-.
# https://stackoverflow.com/questions/161510/pass-parameter-by-reference-in-ruby
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

# Transparent UDP proxy class.
class Proxy
  # Initialize the UDP proxy with given arguments.
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
    @worker = Thread.new &method(:worker)
    # If the upstream server is in this network, we need to make sure that its MAC
    # address is discovered and put in the ARP cache before we even start the proxy,
    # otherwise internal connections won't be spoofed and the proxy will be useless
    # until some random event will fill the ARP cache for the server.
    if @ctx.iface.network.include?( @upstream_address )
      Logger.debug "[#{'UDP PROXY'.green}] Sending probe to upstream server address ..."
      BetterCap::Network.get_hw_address( @ctx, @upstream_address )
      # wait for the system to acknowledge the ARP cache changes.
      sleep( 1 )
    end
  end

  # Stop the proxy.
  def stop
    Logger.info "Stopping UDP proxy ..."
    EventMachine.stop
    @worker.join
  end

  private

  def worker
    begin
      up_addr = @upstream_address
      up_port = @upstream_port
      up_svc  = BetterCap::StreamLogger.service( :udp, @upstream_port )

      EM::run do
        Logger.info "[#{'UDP PROXY'.green}] Starting on #{@address}:#{@port} ( -> #{up_addr}:#{up_port} ) ..."
        EM::open_datagram_socket @address, @port, Server, @address, up_addr, up_port
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
