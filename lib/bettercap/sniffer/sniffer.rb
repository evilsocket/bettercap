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

  @@parsers = nil

  def self.start( ctx )
    Logger.info 'Starting sniffer ...'

    pcap = nil

    if !ctx.options[:sniffer_pcap].nil?
      pcap = PcapFile.new
      Logger.warn "Saving packets to #{ctx.options[:sniffer_pcap]} ."
    end

    @@parsers = ParserFactory.load_by_names ctx.options[:parsers]

    cap = Capture.new(
        iface: ctx.options[:iface],
        filter: ctx.options[:sniffer_filter],
        start: true
    )
    cap.stream.each do |p|
      begin
        pcap.array_to_file( filename: ctx.options[:sniffer_pcap], array: [p], append: true) unless pcap.nil?
      rescue Exception => e
        Logger.warn e.message
      end

      begin
        pkt = Packet.parse p
      rescue Exception => e
        pkt = nil
        Logger.debug e.message
      end

      if not pkt.nil? and pkt.is_ip?
        next if ( pkt.ip_saddr == ctx.ifconfig[:ip_saddr] or pkt.ip_daddr == ctx.ifconfig[:ip_saddr] ) and !ctx.options[:local]

        @@parsers.each do |parser|
          begin
            parser.on_packet pkt
          rescue Exception => e
            Logger.warn e.message
          end
        end
      end
    end
  end
end
