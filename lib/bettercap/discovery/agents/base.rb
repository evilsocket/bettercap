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
class Base
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
      ::Thread.new do
        begin
          while ip = @queue.pop(true)
            loop do
              Logger.debug "#{self.class.name} : Probing #{ip} ..."

              begin
                send_probe ip.to_s

                break
              rescue Exception => e
                Logger.debug "#{self.class.name}#send_probe : #{ip} -> #{e.message}"

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
end
end
