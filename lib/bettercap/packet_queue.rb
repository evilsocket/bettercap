=begin
BETTERCAP
Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/
This project is released under the GPL 3 license.
=end
require 'bettercap/error'

module BetterCap
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
    @injector = PacketFu::Inject.new(:iface => iface)
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
    @running = false
    @nworkers.times { push(nil) }
    @workers.map(&:join)
  end

  private

  def dispatch_udp_packet(packet)
    ip, port, data = packet
    Logger.debug "Sending UDP data packet to #{ip}:#{port} ..."
    @udp.send( data, 0, ip, port )
  end

  def dispatch_raw_packet(packet)
    Logger.debug "Sending #{packet.class.name} packet ..."
    @injector.array = [packet.headers[0].to_s]
    @injector.inject
  end

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
