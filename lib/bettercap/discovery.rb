=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
class Discovery
  def initialize( ctx )
    @ctx     = ctx
    @running = false
    @thread  = nil
  end

  def start
    @running = true
    @thread  = Thread.new { worker }
  end

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
      empty_list = @ctx.targets.empty?

      if @ctx.options.should_discover_hosts?
        Logger.info 'Searching for targets ...' if empty_list
      end

      @ctx.targets = Network.get_alive_targets(@ctx).sort_by { |t| t.sortable_ip }

      if empty_list
        Logger.info "Collected #{@ctx.targets.size} total targets."
        @ctx.targets.each do |target|
          Logger.info "  #{target}"
        end
      end
    end
  end
end
