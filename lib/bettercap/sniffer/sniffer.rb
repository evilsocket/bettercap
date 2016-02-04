# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require 'bettercap/logger'
require 'colorize'
require 'packetfu'

module BetterCap
# Class responsible of loading BetterCap::Parsers instances and performing
# network packet sniffing and dumping.
class Sniffer
  include PacketFu

  @@ctx     = nil
  @@parsers = nil
  @@pcap    = nil
  @@cap     = nil

  # Start a new thread that will sniff packets from the network and pass
  # each one of them to the BetterCap::Parsers instances loaded inside the
  # +ctx+ BetterCap::Context instance.
  def self.start( ctx )
    Thread.new do
      Logger.debug 'Starting sniffer ...'

      setup( ctx )

      self.stream.each do |p|
        break unless @@ctx.running
        begin
          parsed = Packet.parse p
        rescue Exception => e
          parsed = nil
          Logger.debug e.message
        end

        if not parsed.nil? and parsed.is_ip? and !skip_packet?(parsed)
          append_packet p
          parse_packet parsed
        end
      end
    end
  end

  private

  # Return the current PCAP stream.
  def self.stream
    if @@ctx.options.sniffer_src.nil?
      @@cap.stream
    else
      Logger.info "Reading packets from #{@@ctx.options.sniffer_src} ..."

      PcapFile.file_to_array @@ctx.options.sniffer_src
    end
  end

  # Return true if the +pkt+ packet instance must be skipped.
  def self.skip_packet?( pkt )
    !@@ctx.options.local and
        ( pkt.ip_saddr == @@ctx.ifconfig[:ip_saddr] or
            pkt.ip_daddr == @@ctx.ifconfig[:ip_saddr] )
  end

  # Apply each parser on the given +parsed+ packet.
  def self.parse_packet( parsed )
    @@parsers.each do |parser|
      begin
        parser.on_packet parsed
      rescue Exception => e
        Logger.warn e.message
      end
    end
  end

  # Append the packet +p+ to the current PCAP file.
  def self.append_packet( p )
    begin
      @@pcap.array_to_file(
          filename: @@ctx.options.sniffer_pcap,
          array: [p],
          append: true ) unless @@pcap.nil?
    rescue Exception => e
      Logger.warn e.message
    end
  end

  # Setup all needed objects for the sniffer using the +ctx+ Context instance.
  def self.setup( ctx )
    @@ctx = ctx

    unless @@ctx.options.sniffer_pcap.nil?
      @@pcap = PcapFile.new
      Logger.warn "Saving packets to #{@@ctx.options.sniffer_pcap} ."
    end

    if @@ctx.options.custom_parser.nil?
      @@parsers = Parsers::Base.load_by_names @@ctx.options.parsers
    else
      @@parsers = Parsers::Base.load_custom @@ctx.options.custom_parser
    end

    @@cap = Capture.new(
        iface: @@ctx.options.iface,
        filter: @@ctx.options.sniffer_filter,
        start: true
    )
  end
end
end
