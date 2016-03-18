# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

module BetterCap

class SpoofOptions
  # Name of the spoofer to use.
  attr_accessor :spoofer
  # If true half duplex mode is enabled.
  attr_accessor :half_duplex
  # If true, bettercap won't forward packets for any target, causing
  # connections to be killed.
  attr_accessor :kill

  def initialize
    @spoofer     = 'ARP'
    @half_duplex = false
    @kill        = false
  end

  def parse!( ctx, opts )
    opts.separator ""
    opts.separator "SPOOFING:".bold
    opts.separator ""

    opts.on( '-S', '--spoofer NAME', "Spoofer module to use, available: #{Spoofers::Base.available.map{|x| x.yellow }.join(', ')} - default: #{@spoofer.yellow}." ) do |v|
      @spoofer = v
    end

    opts.on( '--no-spoofing', "Disable spoofing, alias for #{'--spoofer NONE'.yellow}." ) do
      @spoofer = 'NONE'
    end

    opts.on( '--half-duplex', 'Enable half-duplex MITM, this will make bettercap work in those cases when the router is not vulnerable.' ) do
      @half_duplex = true
    end

    opts.on( '--kill', 'Instead of forwarding packets, this switch will make targets connections to be killed.' ) do
      @kill = true
    end
  end

  # Return true if a spoofer module was specified, otherwise false.
  def enabled?
    @spoofer.upcase != 'NONE'
  end


  # Parse spoofers and return a list of BetterCap::Spoofers objects. Raise a
  # BetterCap::Error if an invalid spoofer name was specified.
  def parse_spoofers
    valid = []
    @spoofer.split(",").each do |module_name|
      valid << Spoofers::Base.get_by_name( module_name )
    end
    valid
  end

end

end
