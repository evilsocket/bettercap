# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
module BetterCap
module Network
# Simple class to perform validation of various addresses, ranges, etc.
class Validator
  # Basic expression to validate an IP address.
  IP_ADDRESS_REGEX = '(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})'
  # Quite self explainatory :)
  IP_OCTECT_MAX    = 255

  # Return true if +ip+ is a valid IP address, otherwise false.
  def self.is_ip?(ip)
    if /\A#{IP_ADDRESS_REGEX}\Z/ =~ ip.to_s
      return $~.captures.all? { |i| i.to_i <= IP_OCTECT_MAX }
    end
    false
  end

  # Return true if +port+ is a valid port, otherwise false.
  def self.is_valid_port?(port)
    port ||= ""
    return false if port.strip.empty?
    return false unless port =~ /^[0-9]+$/
    port = port.to_i
    return ( port > 0 and port <= 65535 )
  end

  # Extract valid IP addresses from +data+ and yields each one of them.
  def self.each_ip(data)
    data.scan(/(#{IP_ADDRESS_REGEX})/).each do |m|
      yield( m[0] ) if m[0] != '0.0.0.0'
    end
  end

  # Return true if +r+ is a valid IP address range ( 192.168.1.1-93 ), otherwise false.
  def self.is_range?(r)
    if /\A#{IP_ADDRESS_REGEX}\-(\d{1,3})\Z/ =~ r.to_s
      return $~.captures.all? { |i| i.to_i <= IP_OCTECT_MAX }
    end
    false
  end

  # Parse +r+ as an IP range and return the first and last IP.
  def self.parse_range(r)
    first, last_part = r.split('-')
    last = first.split('.')[0..2].join('.') + ".#{last_part}"
    first = IPAddr.new(first)
    last  = IPAddr.new(last)

    [ first, last ]
  end

  # Parse +r+ as an IP range and yields each address in it.
  def self.each_in_range(r)
    first, last = self.parse_range(r)
    loop do
      yield first.to_s
      break if first == last
      first = first.succ
    end
  end

  # Parse +m+ as a netmask and yields each address in it.
  def self.each_in_netmask(m)
    IPAddr.new(m).to_range.each do |o|
       yield o.to_s
    end
  end

  # Return true if +n+ is a valid IP netmask range ( 192.168.1.1/24 ), otherwise false.
  def self.is_netmask?(n)
    if /\A#{IP_ADDRESS_REGEX}\/(\d+)\Z/ =~ n.to_s
      return $~.captures.all? { |i| i.to_i <= IP_OCTECT_MAX }
    end
    false
  end

  # Return true if +mac+ is a valid MAC address, otherwise false.
  def self.is_mac?(mac)
    ( /^[a-f0-9]{1,2}\:[a-f0-9]{1,2}\:[a-f0-9]{1,2}\:[a-f0-9]{1,2}\:[a-f0-9]{1,2}\:[a-f0-9]{1,2}$/i =~ mac.to_s )
  end
end

end
end
