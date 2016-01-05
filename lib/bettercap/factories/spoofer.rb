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
class Spoofer
  class << self
    def available
      avail = []
      Dir.foreach( File.dirname(__FILE__) + '/../spoofers/') do |file|
        if file =~ /.rb/
          avail << file.gsub('.rb','').upcase
        end
      end
      avail
    end

    def get_by_name(name)
      raise BetterCap::Error, "Invalid spoofer name '#{name}'!" unless available? name

      name.downcase!

      require_relative "../spoofers/#{name}"

      Kernel.const_get("BetterCap::#{name.capitalize}Spoofer").new
    end

    private

    def available?(name)
      available.include?(name)
    end
  end
end
end
end
