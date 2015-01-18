=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require_relative '../firewalls/osx'
require_relative '../firewalls/linux'

class FirewallFactory
  @@instance = nil

  def FirewallFactory.get_firewall
    return @@instance unless @@instance.nil?

    if RUBY_PLATFORM =~ /darwin/
      @@instance = OSXFirewall.new
    elsif RUBY_PLATFORM =~ /linux/
      @@instance = LinuxFirewall.new
    else
      raise "Unsupported operating system"
    end

    @@instance
  end
end
