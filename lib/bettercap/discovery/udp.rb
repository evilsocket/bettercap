=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require 'bettercap/logger'

# Send UDP probes trying to filling the ARP table.
class UdpAgent
  def initialize( ifconfig, gw_ip, local_ip )
    @ifconfig = ifconfig
    @port = 137
    @message =
      "\x82\x28\x00\x00\x00" +
      "\x01\x00\x00\x00\x00" +
      "\x00\x00\x20\x43\x4B" +
      "\x41\x41\x41\x41\x41" +
      "\x41\x41\x41\x41\x41" +
      "\x41\x41\x41\x41\x41" +
      "\x41\x41\x41\x41\x41" +
      "\x41\x41\x41\x41\x41" +
      "\x41\x41\x41\x41\x41" +
      "\x00\x00\x21\x00\x01"

    @queue = Queue.new

    net = ip = @ifconfig[:ip4_obj]

    # loop each ip in our subnet and push it to the queue    
    while net.include?ip
      # rescanning the gateway could cause an issue when the 
      # gateway itself has multiple interfaces ( LAN, WAN ... )
      if ip != gw_ip and ip != local_ip
        @queue.push ip
      end

      ip = ip.succ
    end

    # spawn the workers! ( tnx to https://blog.engineyard.com/2014/ruby-thread-pool )
    @workers = (0...4).map do
      Thread.new do
        begin
          while ip = @queue.pop(true)
            Logger.debug "Probing #{ip} ..."

            # send netbios udp packet, just to fill ARP table            
            sd = UDPSocket.new
            sd.send( @message, 0, ip.to_s, @port )
            sd = nil
            # TODO: Parse response for hostname?
          end
        rescue Exception => e
          Logger.debug "#{ip} -> #{e.message}"
        end
      end
    end
  end

  def wait
    begin
      @workers.map(&:join) 
    rescue Exception => e
      Logger.debug "UdpAgent.wait: #{e.message}"
    end
  end
end

