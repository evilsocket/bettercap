# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require 'bettercap/spoofers/base'
require 'bettercap/logger'

module BetterCap
module Spoofers
# Dummy class used to disable spoofing.
class None < Base
  # Initialize the non-spoofing class.
  def initialize
    Logger.debug 'Spoofing disabled.'

    @ctx     = Context.get
    @gateway = nil
    @thread  = nil
    @running = false

    update_gateway!
  end

  # Start the "NONE" spoofer.
  def start
    stop() if @running
    @running = true

    @thread = Thread.new { fake_spoofer }
  end

  # Stop the "NONE" spoofer.
  def stop
    return unless @running

    @running = false
    begin
      @thread.exit
    rescue
    end
  end

  private

  # Main fake spoofer loop.
  def fake_spoofer
    spoof_loop(1) { |target| }
  end

end
end
end
