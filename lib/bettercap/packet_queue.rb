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
    @queue    = Queue.new
    @workers  = (0...nworkers).map {
      ::Thread.new {
        Logger.debug "PacketQueue worker started."
        begin
          while @running do
            packet = @queue.pop
            if packet.nil?
              Logger.debug "Got nil packet, PacketQueue stopping ..."
              break
            end

            Logger.debug "Sending #{packet.class.name} packet ..."

            packet.to_w(@iface)
          end
        rescue Exception => e
          Logger.debug "#{self.class.name} ( #{packet.class.name} ) : #{e.message}"
          if e.message.include? 'Too many open files'
            Logger.debug "Repushing #{self.class.name} to the packet queue ..."
            push(packet)
          end
        end
        Logger.debug "PacketQueue worker stopped."
      }
    }
  end

  # Push a packet to the queue.
  def push packet
    @queue.push(packet)
  end

  # Notify the queue to stop and wait for every worker to finish.
  def stop
    @running = false
    @nworkers.times { push(nil) }
    @workers.map(&:join)
  end
end
end
