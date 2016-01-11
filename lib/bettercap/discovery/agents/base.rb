=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

# Base class for discovery agents.
module BetterCap
module Discovery
module Agents
# Base class for BetterCap::Discovery::Agents.
class Base
  # Initialize the agent using the +ctx+ BetterCap::Context instance.
  def initialize( ctx )
    @ctx      = ctx
    @ifconfig = ctx.ifconfig
    @local_ip = @ifconfig[:ip_saddr]
    @queue    = Queue.new

    net = ip = @ifconfig[:ip4_obj]

    # loop each ip in our subnet and push it to the queue
    while net.include?ip
      # rescanning the gateway could cause an issue when the
      # gateway itself has multiple interfaces ( LAN, WAN ... )
      if ip != ctx.gateway and ip != @local_ip
        @queue.push ip
      end

      ip = ip.succ
    end

    # spawn the workers! ( tnx to https://blog.engineyard.com/2014/ruby-thread-pool )
    @workers = (0...4).map do
      ::Thread.new do
        begin
          while ip = @queue.pop(true)
            loop do
              begin
                send_probe ip.to_s

                break
              rescue Exception => e
                # Logger.debug "#{self.class.name}#send_probe : #{ip} -> #{e.message}"

                # If we've got an error message such as:
                #   (cannot open BPF device) /dev/bpf0: Too many open files
                # We want to retry to probe this ip in a while.
                if e.message.include? 'Too many open files'
                  Logger.debug "Retrying #{self.class.name}#send_probe on #{ip} in 1 second."

                  sleep 1
                else
                  break
                end
              end
            end
          end
        rescue; end
      end
    end
  end

  # Wait for all the probes to be sent by this agent.
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
end
end
