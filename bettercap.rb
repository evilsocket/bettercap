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
require_relative 'lib/factories/parser_factory'
require_relative 'lib/logger'
require_relative 'lib/shell'
require_relative 'lib/network'
require_relative 'lib/version'
require_relative 'lib/target'
require_relative 'lib/sniffer'

begin

  raise 'This software must run as root.' unless Process.uid == 0

  options = {
    :iface => Pcap.lookupdev,
    :spoofer => 'ARP',
    :target => nil,
    :logfile => nil,
    :sniffer => false,
    :parsers => ['*'],
    :local => false
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

    opts.on( "-O", "--log LOG_FILE", "Log all messagges into a file, if not specified the log messages will be only print into the shell." ) do |v|
      options[:logfile] = v
    end

    opts.on( '-L', "--local", "Parse packets coming from/to the address of this computer, default to False." ) do
      options[:local] = true
    end

    opts.on( "-X", "--sniffer", "Enable sniffer." ) do
      options[:sniffer] = true
    end

    opts.on( "-P", "--parsers PARSERS", "Comma separated list of packet parsers to enable, '*' for all ( NOTE: Will set -X to true ), available: " + ParserFactory.available.join(', ') + " - default: *" ) do |v|
      options[:sniffer] = true      
      options[:parsers] = ParserFactory.from_cmdline(v)
    end
  end.parse!

  Logger.logfile = options[:logfile]
  iface    = PacketFu::Utils.whoami? :iface => options[:iface]
  ifconfig = PacketFu::Utils.ifconfig options[:iface]
  network  = ifconfig[:ip4_obj]
  firewall = FirewallFactory.get_firewall
  gateway  = Network.get_gateway
  targets  = nil

  raise "Could not determine IPv4 address of '#{options[:iface]}' interface." unless !network.nil?

  if options[:target].nil?
    Logger.info "Targeting the whole subnet #{network.to_range} ..."

    targets = Network.get_alive_targets ifconfig, gateway, iface[:ip_saddr]

    raise "No alive targets found." unless targets.size > 0

    Logger.info "Collected #{targets.size} total targets."
  else
    raise "Invalid target '#{options[:target]}'" unless Network.is_ip? options[:target]

    targets = [ Target.new( options[:target], nil ) ]
  end

  Logger.info "[-] Local Address : #{iface[:ip_saddr]}"
  Logger.info "[-] Local MAC     : #{iface[:eth_saddr]}"
  Logger.info "[-] Gateway       : #{gateway}"

  Logger.info "Module: " + options[:spoofer]

  spoofer = SpooferFactory.get_by_name( options[:spoofer], iface, gateway, targets )

  spoofer.start

  Logger.write "\n"
  
  if options[:sniffer]
      Sniffer.start( options[:parsers], options[:iface], iface[:ip_saddr], options[:local] )
  else
      loop do
        sleep 1
      end
  end

rescue SystemExit, Interrupt

rescue Exception => e
  Logger.error e.message
  Logger.error e.backtrace.join("\n")

ensure
  if not spoofer.nil?
    spoofer.stop
  end

  if not firewall.nil?
    firewall.enable_forwarding(false)
  end
end
