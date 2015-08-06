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

module BetterCap
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

    private

    def self.skip_packet?( pkt )
      !@@ctx.options[:local] and
        ( pkt.ip_saddr == @@ctx.ifconfig[:ip_saddr] or
         pkt.ip_daddr == @@ctx.ifconfig[:ip_saddr] )
    end

    def self.parse_packet( parsed )
      @@parsers.each do |parser|
        begin
          parser.on_packet parsed
        rescue Exception => e
          Logger.warn e.message
        end
      end
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
end
