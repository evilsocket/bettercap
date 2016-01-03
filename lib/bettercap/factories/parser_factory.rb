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
class ParserFactory
  @@path = File.dirname(__FILE__) + '/../sniffer/parsers/'

  class << self
    def available
      avail = []
      Dir.foreach( @@path ) do |file|
        if file =~ /.rb/ and file != 'base.rb' and file != 'custom.rb'
          avail << file.gsub('.rb','').upcase
        end
      end
      avail
    end

    def from_cmdline(v)
      raise BetterCap::Error, "No parser names provided" if v.nil?

      avail = available
      list = v.split(',').collect(&:strip).collect(&:upcase).reject{ |c| c.empty? }
      list.each do |parser|
          raise BetterCap::Error, "Invalid parser name '#{parser}'." unless avail.include?(parser) or parser == '*'
      end
      list
    end

    def load_by_names(parsers)
      loaded = []
      Dir.foreach( @@path ) do |file|
        cname = file.gsub('.rb','').upcase
        if file =~ /.rb/ and file != 'base.rb' and file != 'custom.rb' and ( parsers.include?(cname) or parsers == ['*'] )
          Logger.debug "Loading parser #{cname} ..."

          require_relative "#{@@path}#{file}"

          loaded << Kernel.const_get("BetterCap::#{cname.capitalize}Parser").new
        end
      end
      loaded
    end

    def load_custom(expression)
      require_relative "#{@@path}custom.rb"
      [ BetterCap::CustomParser.new(expression) ]
    end
  end
end
end
