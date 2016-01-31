# encoding: UTF-8
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

  # Return true if the +list+ of targets includes +target+.
  def list_include_target?( list, target )
    list.each do |t|
      if t.equals?(target.ip, target.mac)
        return true
      end
    end
    false
  end

  # Print informations about new and lost targets.
  def print_differences( prev )
    diff = { :new => [], :lost => [] }

    @ctx.targets.each do |target|
      unless list_include_target?( prev, target )
        diff[:new] << target
      end
    end

    prev.each do |target|
      unless list_include_target?( @ctx.targets, target )
        diff[:lost] << target
      end
    end

    unless diff[:new].empty? and diff[:lost].empty?
      if diff[:new].empty?
        snew = ""
      else
        snew = "Acquired #{diff[:new].size} new target#{if diff[:new].size > 1 then "s" else "" end}"
      end

      if diff[:lost].empty?
        slost = ""
      else
        slost = "#{if snew == "" then 'L' else ', l' end}ost #{diff[:lost].size} target#{if diff[:lost].size > 1 then "s" else "" end}"
      end

      Logger.info "#{snew}#{slost} :"

      msg = "\n"
      diff[:new].each do |target|
        msg += "  [#{'NEW'.green}] #{target.to_s(false)}\n"
      end
      diff[:lost].each do |target|
        msg += "  [#{'LOST'.red}] #{target.to_s(false)}\n"
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

      print_differences( prev ) unless @ctx.options.arpcache

      prev = @ctx.targets

      sleep(5) if @ctx.options.arpcache
    end
  end
end
end
end
