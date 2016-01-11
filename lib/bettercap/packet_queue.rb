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
  def initialize( iface, nworkers = 4 )
    @iface    = iface
    @nworkers = nworkers
    @running  = true
    @injector = PacketFu::Inject.new(:iface => iface)
    @queue    = Queue.new
    @workers  = (0...nworkers).map {
      ::Thread.new {
        Logger.debug "PacketQueue worker started."

        while @running
          begin
            packet = @queue.pop
            # nil packet pushed to signal stopping
            if packet.nil?
              Logger.debug "Got nil packet, PacketQueue stopping ..."
              break

            # [ ip, port, data ] pushed by Discovery::Agents::Udp
            elsif packet.is_a?(Array)
              ip, port, data = packet
              Logger.debug "Sending UDP data packet to #{ip}:#{port} ..."

              # TODO: Maybe just create one globally?
              sd = UDPSocket.new
              sd.send( data, 0, ip, port )
              sd = nil

            # PacketFu packet
            else
              Logger.debug "Sending #{packet.class.name} packet ..."

              # Use a global PacketFu::Inject object.
              @injector.array = [packet.headers[0].to_s]
              @injector.inject
            end
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
      }
    }
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
end
end
