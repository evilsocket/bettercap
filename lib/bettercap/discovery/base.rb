=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require 'bettercap/logger'

# Base class for discovery agents.
module BetterCap
  class BaseAgent
    def initialize( ifconfig, gw_ip, local_ip )
      @local_ip = local_ip
      @ifconfig = ifconfig
      @queue    = Queue.new

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
              Logger.debug "#{self.class.name} : Probing #{ip} ..."

              send_probe ip.to_s
            end
          rescue Exception => e
            Logger.debug "#{self.class.name} : #{ip} -> #{e.message}"
          end
        end
      end
    end

    def wait
      begin
        @workers.map(&:join)
      rescue Exception => e
        Logger.debug "#{self.class.name}.wait: #{e.message}"
      end
    end

    private

    def send_probe( ip )
      Logger.warn "#{self.class.name} not implemented!"
    end
  end
end
