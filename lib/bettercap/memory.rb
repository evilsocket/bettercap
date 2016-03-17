# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

module BetterCap
# This class is responsible for garbage collection and memory stats printing.
class Memory
  def initialize
    GC.enable
    s = GC.stat
    @total_allocs = s[:total_allocated_objects]
    @total_freed  = s[:total_freed_objects]
  end

  def optimize!
    GC.start
    begin
      s          = GC.stat
      new_allocs = s[:total_allocated_objects]
      new_freed  = s[:total_freed_objects]
      allocs_d   = nil
      freed_d    = nil

      if new_allocs < @total_allocs
        allocs_d = new_allocs.to_s.green
      elsif new_allocs > @total_allocs
        allocs_d = new_allocs.to_s.red
      else
        allocs_d = new_allocs
      end

      if new_freed < @total_freed
        freed_d = new_freed.to_s.red
      elsif new_freed > @total_freed
        freed_d = new_freed.to_s.green
      else
        freed_d = new_freed
      end

      # Logger.debug "GC: allocd objects: #{allocs_d} freed objects: #{freed_d}"

      @total_allocs = new_allocs
      @total_freed  = new_freed
    rescue; end
  end
end
end
