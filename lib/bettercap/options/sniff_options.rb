# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

module BetterCap

class SniffOptions
  # If true the BetterCap::Sniffer will be enabled.
  attr_accessor :enabled
  # PCAP file name to save captured packets to.
  attr_accessor :output
  # BPF filter to apply to sniffed packets.
  attr_accessor :filter
  # Input PCAP file, if specified the BetterCap::Sniffer will read packets
  # from it instead of the network.
  attr_accessor :src
  # Comma separated list of BetterCap::Parsers to enable.
  attr_accessor :parsers
  # Regular expression to use with the BetterCap::Parsers::Custom parser.
  attr_accessor :custom_parser
  # If true, bettercap will sniff packets from the local interface as well.
  attr_accessor :local

  def initialize
    @enabled       = false
    @output        = nil
    @filter        = nil
    @src           = nil
    @parsers       = ['*']
    @custom_parser = nil
    @local         = false
  end

  def parse!( ctx, opts )
    opts.separator ""
    opts.separator "SNIFFING:".bold
    opts.separator ""

    opts.on( '-X', '--sniffer', 'Enable sniffer.' ) do
      @enabled = true
    end

    opts.on( '-L', '--local', "Parse packets coming from/to the address of this computer ( NOTE: Will set -X to true ), default to #{'false'.yellow}." ) do
      @enabled = true
      @local = true
    end

    opts.on( '--sniffer-source FILE', 'Load packets from the specified PCAP file instead of the interface ( will enable sniffer ).' ) do |v|
      @enabled = true
      @src = File.expand_path v
    end

    opts.on( '--sniffer-output FILE', 'Save all packets to the specified PCAP file ( will enable sniffer ).' ) do |v|
      @enabled = true
      @output = File.expand_path v
    end

    opts.on( '--sniffer-filter EXPRESSION', 'Configure the sniffer to use this BPF filter ( will enable sniffer ).' ) do |v|
      @enabled = true
      @filter = v
    end

    opts.on( '-P', '--parsers PARSERS', "Comma separated list of packet parsers to enable, '*' for all ( NOTE: Will set -X to true ), available: #{Parsers::Base.available.map { |x| x.yellow }.join(', ')} - default: #{'*'.yellow}" ) do |v|
      @enabled = true
      @parsers = Parsers::Base.from_cmdline(v)
    end

    opts.on( '--custom-parser EXPRESSION', 'Use a custom regular expression in order to capture and show sniffed data ( NOTE: Will set -X to true ).' ) do |v|
      @enabled       = true
      @parsers       = ['CUSTOM']
      @custom_parser = Regexp.new(v)
    end
  end

  # Return true if the specified +parser+ is enabled, otherwise false.
  def enabled?( parser = nil )
    @enabled and ( parser.nil? or ( @parsers.include?('*') or @parsers.include?(parser.upcase) ) )
  end
end

end
