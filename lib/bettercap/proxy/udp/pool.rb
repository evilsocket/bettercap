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

class Client < EM::Connection
  attr_accessor :client_ip, :client_port

  def initialize(client_ip, client_port, server)
    @client_ip, @client_port = client_ip, client_port
    @server = server
  end

  # upstream -> ip
  def receive_data(data)
    port, ip = Socket.unpack_sockaddr_in(get_peername)
    event    = Event.new( ip, port, data )

    Logger.info "[#{'UDP PROXY'.green}] #{'upstream'.yellow}:#{@server.relay_port} #{'->'.green} #{ip} ( #{event.data.bytesize} bytes )"

    Module.dispatch( 'on_response', event )

    @server.send_datagram( event.data, client_ip, client_port )
  end
end

class Server < EM::Connection
  attr_accessor :relay_ip, :relay_port

  def initialize(address, relay_ip, relay_port)
    @relay_ip, @relay_port = relay_ip, relay_port
    @pool = Pool.new(self, address)
  end

  # ip -> upstream
  def receive_data(data)
    port, ip = Socket.unpack_sockaddr_in(get_peername)
    client = @pool.client(ip, port)
    event = Event.new( ip, port, data )

    Logger.info "[#{'UDP PROXY'.green}] #{ip} #{'->'.green} #{'upstream'.yellow}:#{@relay_port} ( #{event.data.bytesize} bytes )"

    Module.dispatch( 'on_data', event )

    client.send_datagram( event.data, @relay_ip, @relay_port )
  end
end

class Pool
  def initialize(server, address)
    @address = address
    @clients = {}
    @server = server
  end

  def client(ip, port)
    @clients[key(ip, port)] || @clients[key(ip,port)] = create_client(ip, port)
  end

  private

  def key(ip, port)
    "#{ip}:#{port}"
  end

  def create_client(ip, port)
    Logger.debug "#{'UDP'.green} Creating new client for #{ip}:#{port}" 
    client = EM::open_datagram_socket @address, 0, Client, ip, port, @server
  end
end

end
end
end
