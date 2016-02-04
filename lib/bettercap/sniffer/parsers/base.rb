# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
module BetterCap
module Parsers
# Base class for BetterCap::Parsers.
class Base
  # Hash of available parsers ( parser name -> class name )
  @@loaded = {}

  class << self
    # Called when this base class is inherited from one of the parsers.
    def inherited(subclass)
      name = subclass.name.split('::')[2].upcase
      if name != 'CUSTOM'
        @@loaded[name] = subclass.name
      end
    end

    # Return a list of available parsers names.
    def available
      @@loaded.keys
    end

    # Parse the +v+ command line argument and return a list of parser names.
    # Will raise BetterCap::Error if one or more parser names are not valid.
    def from_cmdline(v)
      raise BetterCap::Error, "No parser names provided" if v.nil?

      avail = available
      list = v.split(',').collect(&:strip).collect(&:upcase).reject{ |c| c.empty? }
      list.each do |parser|
        raise BetterCap::Error, "Invalid parser name '#{parser}'." unless avail.include?(parser) or parser == '*'
      end
      list
    end

    # Return a list of BetterCap::Parsers instances by their +parsers+ names.
    def load_by_names(parsers)
      loaded = []

      @@loaded.each do |name,cname|
        if parsers.include?(name) or parsers == ['*']
          Logger.debug "Loading parser #{name} ( #{cname} ) ..."
          loaded << BetterCap::Loader.load(cname).new
        end
      end

      loaded
    end

    # Load and return an instance of the BetterCap::Parsers::Custom parser
    # given the +expression+ Regex object.
    def load_custom(expression)
      Logger.debug "Loading custom parser: '#{expression}' ..."
      [ BetterCap::Parsers::Custom.new(expression) ]
    end
  end

  # Initialize this parser.
  def initialize
    @filters = []
    @name = 'BASE'
  end

  # This method will be called from the BetterCap::Sniffer for each
  # incoming packet ( +pkt ) and will apply the parser filter to it.
  def on_packet( pkt )
    s = pkt.to_s
    @filters.each do |filter|
      if s =~ filter
        StreamLogger.log_raw( pkt, @name, pkt.payload )
      end
    end
  end
end
end
end
