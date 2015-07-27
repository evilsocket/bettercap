=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require 'bettercap/logger'
require 'bettercap/factories/parser_factory'
require 'colorize'
require 'packetfu'

class Sniffer
  include PacketFu

  @@ctx     = nil
  @@parsers = nil
  @@pcap    = nil
  @@cap     = nil

  def self.start( ctx )
    Logger.info 'Starting sniffer ...'

    setup( ctx )

    @@cap.stream.each do |p|
      append_packet p
      parse_packet p
    end
  end

  private

  def self.parse_packet( p )
    begin
      pkt = Packet.parse p
    rescue Exception => e
      pkt = nil
      Logger.debug e.message
    end

    if not pkt.nil? and pkt.is_ip?
      next if skip_packet? pkt

      @@parsers.each do |parser|
        begin
          parser.on_packet pkt
        rescue Exception => e
          Logger.warn e.message
        end
      end
    end
  end

  def self.skip_packet?( pkt )
    !@@ctx.options[:local] and
    ( pkt.ip_saddr == @@ctx.ifconfig[:ip_saddr] or
      pkt.ip_daddr == @@ctx.ifconfig[:ip_saddr] )
  end

  def self.append_packet( p )
    begin
      @@pcap.array_to_file(
          filename: @@ctx.options[:sniffer_pcap],
          array: [p],
          append: true ) unless @@pcap.nil?
    rescue Exception => e
      Logger.warn e.message
    end
  end

  def self.setup( ctx )
    @@ctx = ctx

    if !@@ctx.options[:sniffer_pcap].nil?
      @@pcap = PcapFile.new
      Logger.warn "Saving packets to #{@@ctx.options[:sniffer_pcap]} ."
    end

    @@parsers = ParserFactory.load_by_names @@ctx.options[:parsers]

    @@cap = Capture.new(
        iface: @@ctx.options[:iface],
        filter: @@ctx.options[:sniffer_filter],
        start: true
    )
  end
end
