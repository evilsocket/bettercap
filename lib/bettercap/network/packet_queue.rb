# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require 'bettercap/error'

module BetterCap
module Network
# This class is responsible for sending various network packets.
class PacketQueue
  # Initialize the PacketQueue, it will spawn +nworkers+ thread and
  # will send packets to the +iface+ network interface.
  # If +packet_throttle+ is different than 0.0, it will be used as
  # a delay between each packet to be sent.
  def initialize( iface, packet_throttle = 0.0, nworkers = 4 )
    @iface    = iface
    @nworkers = nworkers
    @throttle = packet_throttle;
    @running  = true
    @stream   = Pcap.open_live( iface, 0xffff, false , 1 )
    @mutex    = Mutex.new
    @udp      = UDPSocket.new
    @queue    = Queue.new
    @workers  = (0...nworkers).map { ::Thread.new { worker } }
  end

  # Push a packet to the queue.
  def push(packet)
    @queue.push(packet)
  end

  # Wait for the packet queue to be empty.
  def wait_empty( timeout )
    begin
      Timeout::timeout(timeout) {
        while !@queue.empty?
          sleep 0.5
        end
      }
    rescue; end
  end

  # Notify the queue to stop and wait for every worker to finish.
  def stop
    wait_empty( 60 )
    @running = false
    @nworkers.times { push(nil) }
    @workers.map(&:join)
  end

  private

  # Unpack [ ip, port, data ] from +packet+ and send it using the global
  # UDPSocket instance.
  def dispatch_udp_packet(packet)
    ip, port, data = packet
    @mutex.synchronize {
      Logger.debug "Sending UDP data packet to #{ip}:#{port} ..."
      @udp.send( data, 0, ip, port )
    }
  end

  # Use the global Pcap injection instance to send the +packet+.
  def dispatch_raw_packet(packet)
    @mutex.synchronize {
      Logger.debug "Sending #{packet.class.name} packet ..."
      @stream.inject( packet.headers[0].to_s )
    }
  end

  # Main PacketQueue logic.
  def worker
    Logger.debug "PacketQueue worker started."

    while @running
      begin
        packet = @queue.pop
        case packet
        # nil packet pushed to signal stopping
        when nil
          Logger.debug "Got nil packet, PacketQueue stopping ..."
          break
        # [ ip, port, data ] pushed by Discovery::Agents::Udp
        when Array
          dispatch_udp_packet(packet)
        # PacketFu raw packet
        when Object
          dispatch_raw_packet(packet)
        end

        sleep(@throttle) if @throttle != 0.0

      rescue Exception => e
        Logger.debug "#{self.class.name} ( #{packet.class.name} ) : #{e.message}"

        # If we've got an error message such as:
        #   (cannot open BPF device) /dev/bpf0: Too many open files
        # We want to retry to probe this ip in a while.
        if e.message.include? 'Too many open files'
          Logger.debug "Repushing #{self.class.name} to the packet queue ..."
          push(packet)
        end
      end
    end

    Logger.debug "PacketQueue worker stopped."
  end
end
end
end
