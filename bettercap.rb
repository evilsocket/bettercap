#!/usr/bin/env ruby

=begin

  BETTERCAP

  Author : Simone 'evilsocket' Margaritelli
  Email  : evilsocket@gmail.com
  Blog   : http://www.evilsocket.net/

  This project is released under the GPL 3 license.

=end
require 'optparse'
require 'colorize'
require 'packetfu'

require_relative 'lib/factories/firewall_factory'
require_relative 'lib/factories/spoofer_factory'
require_relative 'lib/factories/log_factory'
require_relative 'lib/network'
require_relative 'lib/version'

options = {
  :iface => Pcap.lookupdev,
  :spoofer => 'ARP',
  :target => nil
}

puts "---------------------------------------------------------".yellow
puts "                   BETTERCAP v#{BetterCap::VERSION}\n\n".green
puts "          by Simone 'evilsocket' Margaritelli".green
puts "                  evilsocket@gmail.com    ".green
puts "---------------------------------------------------------\n\n".yellow

OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"

  opts.on( "-I", "--interface IFACE", "Network interface name - default: " + options[:iface] ) do |v|
    options[:iface] = v
  end

  opts.on( "-S", "--spoofer NAME", "Spoofer module to use, available: " + SpooferFactory.available.join(', ') + " - default: " + options[:spoofer] ) do |v|
    options[:spoofer] = v
  end

  opts.on( "-T", "--target ADDRESS", "Target ip address." ) do |v|
    options[:target] = v
  end
end.parse!

begin

  raise 'This software must run as root.' unless Process.uid == 0

  iface    = PacketFu::Utils.whoami? :iface => options[:iface]
  firewall = FirewallFactory.get_firewall
  gateway  = Network.get_gateway
  log      = LogFactory.get()

  raise "Invalid target '#{options[:target]}'" unless Network.is_ip? options[:target]

  log.info "[-] Local Address : #{iface[:ip_saddr]}"
  log.info "[-] Local MAC     : #{iface[:eth_saddr]}"
  log.info "[-] Gateway       : #{gateway}"

  spoofer = SpooferFactory.get_by_name( options[:spoofer], iface, gateway, options[:target] )

  spoofer.start

  loop do
    sleep 1
  end

rescue Interrupt

  log.info "Exiting ...".yellow

rescue Exception => e

  log.error "#{e}".red

ensure
  if not spoofer.nil?
    spoofer.stop
  end

  if not firewall.nil?
    firewall.enable_forwarding(false)
  end
end
