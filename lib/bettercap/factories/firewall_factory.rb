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
  class FirewallFactory
    @@instance = nil

    def self.get_firewall
      return @@instance unless @@instance.nil?

      if RUBY_PLATFORM =~ /darwin/
        @@instance = OSXFirewall.new
      elsif RUBY_PLATFORM =~ /linux/
        @@instance = LinuxFirewall.new
      else
        raise BetterCap::Error, 'Unsupported operating system'
      end

      @@instance
    end

    def FirewallFactory.clear_firewall
      @@instance = nil
    end
  end
end
