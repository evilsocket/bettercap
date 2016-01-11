=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
module BetterCap
module Discovery
# Class responsible to actively discover targets on the network.
class Thread
  # Initialize the class using the +ctx+ BetterCap::Context instance.
  def initialize( ctx )
    @ctx     = ctx
    @running = false
    @thread  = nil
  end

  # Start the active network discovery thread.
  def start
    @running = true
    @thread  = ::Thread.new { worker }
  end

  # Stop the active network discovery thread.
  def stop
    @running = false
    if @thread != nil
      Logger.info( 'Stopping network discovery thread ...' ) unless @ctx.options.arpcache
      begin
        @thread.exit
      rescue
      end
    end
  end

  private

  def worker
    Logger.debug( 'Network discovery thread started.' ) unless @ctx.options.arpcache

    while @running
      was_empty = @ctx.targets.empty?
      @ctx.targets = Network.get_alive_targets(@ctx).sort_by { |t| t.sortable_ip }

      if was_empty and not @ctx.targets.empty?
        Logger.info "Collected #{@ctx.targets.size} total targets."

        msg = "\n"
        @ctx.targets.each do |target|
          msg += "  #{target}\n"
        end
        Logger.raw msg
      end

      sleep(5) if @ctx.options.arpcache
    end
  end
end
end
end
