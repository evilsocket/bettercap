=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require 'bettercap/error'

module BetterCap
module Factories
# Factory class responsible for listing, parsing and creating BetterCap::Spoofers
# object instances.
class Spoofer
  class << self
    # Return a list of available spoofers.
    def available
      avail = []
      Dir.foreach( File.dirname(__FILE__) + '/../spoofers/') do |file|
        if file =~ /.rb/ and file != 'base.rb'
          avail << file.gsub('.rb','').upcase
        end
      end
      avail
    end

    # Create an instance of a BetterCap::Spoofers object given its +name+.
    # Will raise a BetterCap::Error if +name+ is not valid.
    def get_by_name(name)
      raise BetterCap::Error, "Invalid spoofer name '#{name}'!" unless available? name

      name.downcase!

      require_relative "../spoofers/#{name}"

      Kernel.const_get("BetterCap::Spoofers::#{name.capitalize}").new
    end

    private

    def available?(name)
      available.include?(name)
    end
  end
end
end
end
