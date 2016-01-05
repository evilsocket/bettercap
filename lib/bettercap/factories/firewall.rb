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
# Factory class responsible of creating the correct object for the current
# operating system of the user.
class Firewall
  @@instance = nil
  # Save and return an instance of the appropriate BetterCap::Firewalls object.
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
  # Clear the instance of the BetterCap::Firewalls object.
  def self.clear
    @@instance = nil
  end
end
end
end
