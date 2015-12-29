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
    Logger.info( 'Network discovery thread started.' ) unless @ctx.options.arpcache

    while @running
      empty_list = false

      if @ctx.targets.empty? and @ctx.options.should_discover_hosts?
        empty_list = true
        Logger.info 'Searching for alive targets ...'
      else
        # make sure we don't stress the logging system
        10.times do
          sleep 1
          if !@running
            break
          end
        end
      end

      @ctx.targets = Network.get_alive_targets ctx

      if empty_list and @ctx.options.should_discover_hosts?
        Logger.info "Collected #{@ctx.targets.size} total targets."
        @ctx.targets.each do |target|
          Logger.info "  #{target}"
        end
      end
    end
  end
end
