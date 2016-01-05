=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

# Send a broadcast ping trying to filling the ARP table.
module BetterCap
module Discovery
module Agents
class Icmp
  def initialize( timeout = 5 )
    @thread = ::Thread.new {
      Factories::Firewall.get.enable_icmp_bcast(true)

      if RUBY_PLATFORM =~ /darwin/
        ping = Shell.execute("ping -i #{timeout} -c 2 255.255.255.255")
      elsif RUBY_PLATFORM =~ /linux/
        ping = Shell.execute("ping -i #{timeout} -c 2 -b 255.255.255.255 2> /dev/null")
      end
    }
  end

  def wait
    begin
      @thread.join
    rescue Exception => e
      Logger.debug "IcmpAgent.wait: #{e.message}"
    end
  end
end
end
end
end
