=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

require 'bettercap/error'
require 'bettercap/logger'

module BetterCap
module Factories
# Factory class responsible for listing, parsing and creating BetterCap::Parsers
# object instances.
class Parser
  @@path = File.dirname(__FILE__) + '/../sniffer/parsers/'

  class << self
    # Return a list of available parsers.
    def available
      avail = []
      Dir.foreach( @@path ) do |file|
        if file =~ /.rb/ and file != 'base.rb' and file != 'custom.rb'
          avail << file.gsub('.rb','').upcase
        end
      end
      avail
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
      Dir.foreach( @@path ) do |file|
        cname = file.gsub('.rb','').upcase
        if file =~ /.rb/ and file != 'base.rb' and file != 'custom.rb' and ( parsers.include?(cname) or parsers == ['*'] )
          Logger.debug "Loading parser #{cname} ..."

          require_relative "#{@@path}#{file}"

          loaded << BetterCap::Loader.load("BetterCap::Parsers::#{cname.capitalize}").new
        end
      end
      loaded
    end

    # Load and return an instance of the BetterCap::Parsers::Custom parser
    # given the +expression+ Regex object.
    def load_custom(expression)
      require_relative "#{@@path}custom.rb"
      [ BetterCap::Parsers::Custom.new(expression) ]
    end
  end
end
end
end
