=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require 'bettercap/error'
require 'bettercap/firewalls/osx'
require 'bettercap/firewalls/linux'

module BetterCap
module Factories
class Firewall
  @@instance = nil

  def self.get
    return @@instance unless @@instance.nil?

    if RUBY_PLATFORM =~ /darwin/
      @@instance = Firewalls::OSX.new
    elsif RUBY_PLATFORM =~ /linux/
      @@instance = Firewalls::Linux.new
    else
      raise BetterCap::Error, 'Unsupported operating system'
    end

    @@instance
  end

  def self.clear
    @@instance = nil
  end
end
end
end
