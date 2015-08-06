#!/usr/bin/env ruby

=begin

  BETTERCAP

  Author : Simone 'evilsocket' Margaritelli
  Email  : evilsocket@gmail.com
  Blog   : http://www.evilsocket.net/

  This project is released under the GPL 3 license.

=end

require 'bettercap/version'
require 'shellwords'

module BetterCap
  module Banner
    def self.print
      $stdout.puts self.banner.green.bold
    end

    def self.banner
      File.read(File.dirname(__FILE__) + '/banner').gsub('#VERSION#', "v#{VERSION}")
    end
  end
end
