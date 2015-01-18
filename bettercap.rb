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
require 'ipaddr'

require_relative 'lib/monkey/packetfu/utils'
require_relative 'lib/factories/firewall_factory'
require_relative 'lib/factories/spoofer_factory'
require_relative 'lib/logger'
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

  opts.on( "-T", "--target ADDRESS", "Target ip address, if not specified the whole subnet will be targeted." ) do |v|
    options[:target] = v
  end
end.parse!

begin

  raise 'This software must run as root.' unless Process.uid == 0

  iface    = PacketFu::Utils.whoami? :iface => options[:iface]
  ifconfig = PacketFu::Utils.ifconfig options[:iface]
  network  = ifconfig[:ip4_obj]
  firewall = FirewallFactory.get_firewall
  gateway  = Network.get_gateway
  targets  = nil

  if options[:target].nil?
    Logger.info "Targeting the whole subnet #{network.to_range} ..."

    targets = Network.get_alive_targets options[:iface], gateway, iface[:ip_saddr]

    Logger.info "Collected #{targets.size} total targets."
  else
    raise "Invalid target '#{options[:target]}'" unless Network.is_ip? options[:target]

    targets = options[:target]
  end

  Logger.info "[-] Local Address : #{iface[:ip_saddr]}"
  Logger.info "[-] Local MAC     : #{iface[:eth_saddr]}"
  Logger.info "[-] Gateway       : #{gateway}"

  spoofer = SpooferFactory.get_by_name( options[:spoofer], iface, gateway, targets )

  spoofer.start

  loop do
    sleep 1
  end

rescue Interrupt

  Logger.info "Exiting ...".yellow

rescue Exception => e

  Logger.error "#{e}".red
  raise e

ensure
  if not spoofer.nil?
    spoofer.stop
  end

  if not firewall.nil?
    firewall.enable_forwarding(false)
  end
end
