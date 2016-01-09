=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
module BetterCap
module Spoofers
# Base class for BetterCap::Spoofers modules.
class Base
  # Will raise NotImplementedError .
  def initialize
    not_implemented_method!
  end
  # Will raise NotImplementedError .
  def start
    not_implemented_method!
  end
  # Will raise NotImplementedError .
  def stop
    not_implemented_method!
  end

private

  def update_targets!
    @ctx.targets.each do |target|
      # targets could change, update mac addresses if needed
      if target.mac.nil?
        hw = Network.get_hw_address( @ctx.ifconfig, target.ip )
        if hw.nil?
          Logger.warn "Couldn't determine target #{ip} MAC!"
          next
        else
          Logger.info "  Target MAC    : #{hw}"
          target.mac = hw
        end
      # target was specified by MAC address
      elsif target.ip_refresh
        ip = Network.get_ip_address( @ctx, target.mac )
        if ip.nil?
          Logger.warn "Couldn't determine target #{target.mac} IP!"
          next
        else
          Logger.info "Target #{target.mac} IP : #{ip}" if target.ip.nil? or target.ip != ip
          target.ip = ip
        end
      end
    end
  end

  def not_implemented_method!
    raise NotImplementedError, 'Spoofers::Base: Unimplemented method!'
  end
end
end
end
