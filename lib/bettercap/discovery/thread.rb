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

  # Print informations about new and lost targets.
  def print_differences( prev_targets )
    size      = @ctx.targets.size
    prev_size = prev_targets.size
    diff      = nil
    label     = nil

    if size > prev_size
      diff  = @ctx.targets - prev_targets
      delta = diff.size
      label = 'NEW'.green

      Logger.warn "Acquired #{delta} new target#{if delta > 1 then "s" else "" end}."
    elsif size < prev_size
      diff  = prev_targets - @ctx.targets
      delta = diff.size
      label = 'LOST'.red

      Logger.warn "Lost #{delta} target#{if delta > 1 then "s" else "" end}."
    end

    unless diff.nil?
      msg = "\n"
      diff.each do |target|
        msg += "  [#{label}] #{target.to_s(false)}\n"
      end
      msg += "\n"
      Logger.raw msg
    end
  end

  # This method implements the main discovery logic, it will be executed within
  # the spawned thread.
  def worker
    Logger.debug( 'Network discovery thread started.' ) unless @ctx.options.arpcache

    prev = []
    while @running
      @ctx.targets = Network.get_alive_targets(@ctx).sort_by { |t| t.sortable_ip }

      print_differences prev

      prev = @ctx.targets

      sleep(5) if @ctx.options.arpcache
    end
  end
end
end
end
