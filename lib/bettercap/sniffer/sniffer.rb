# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

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
    Thread.new {
      Logger.debug 'Starting sniffer ...'

      setup( ctx )

      start     = Time.now
      skipped   = 0
      processed = 0

      self.stream.each do |raw_packet|
        break unless @@ctx.running
        begin
          parsed = PacketFu::Packet.parse(raw_packet)
        rescue Exception => e
          parsed = nil
        end

        if skip_packet?(parsed)
          skipped += 1
        else
          processed += 1
          append_packet raw_packet
          parse_packet parsed
        end
      end

      stop = Time.now
      delta = ( stop - start ) * 1000.0
      total = skipped + processed

      Logger.info "[#{'SNIFFER'.green}] #{total} packets processed in #{delta} ms ( #{skipped} skipped packets, #{processed} processed packets )"
    }
  end

  private

  # Return the current PCAP stream.
  def self.stream
    if @@ctx.options.sniff.src.nil?
      return @@cap.stream
    else
      Logger.info "[#{'SNIFFER'.green}] Reading packets from #{@@ctx.options.sniff.src} ..."

      begin
        return PacketFu::PcapFile.file_to_array @@ctx.options.sniff.src
      rescue Exception => e
        Logger.error "Error while parsing #{@@ctx.options.sniff.src}: #{e.message}"
        Logger.exception e
      end
    end
    return []
  end

  # Return true if the +pkt+ packet instance must be skipped.
  def self.skip_packet?( pkt )
    begin
      # not parsed
      return true if pkt.nil?
      # not IP packet
      return true unless pkt.is_ip?
      # skip if local packet and --local|-L was not specified.
      unless @@ctx.options.sniff.local
        return ( pkt.ip_saddr == @@ctx.iface.ip or pkt.ip_daddr == @@ctx.iface.ip )
      end
    rescue; end
    false
  end

  # Apply each parser on the given +parsed+ packet.
  def self.parse_packet( parsed )
    @@parsers.each do |parser|
      begin
        parser.on_packet parsed
      rescue Exception => e
        Logger.exception e
      end
    end
  end

  # Append the packet +p+ to the current PCAP file.
  def self.append_packet( p )
    begin
      @@pcap.array_to_file(
          filename: @@ctx.options.sniff.output,
          array: [p],
          append: true ) unless @@pcap.nil?
    rescue Exception => e
      Logger.exception e
    end
  end

  # Setup all needed objects for the sniffer using the +ctx+ Context instance.
  def self.setup( ctx )
    @@ctx = ctx

    unless @@ctx.options.sniff.output.nil?
      @@pcap = PacketFu::PcapFile.new
      Logger.info "[#{'SNIFFER'.green}] Saving packets to #{@@ctx.options.sniff.output} ."
    end

    if @@ctx.options.sniff.custom_parser.nil?
      @@parsers = Parsers::Base.load_by_names @@ctx.options.sniff.parsers
    else
      @@parsers = Parsers::Base.load_custom @@ctx.options.sniff.custom_parser
    end

    @@cap = Capture.new(
        iface: @@ctx.options.core.iface,
        filter: @@ctx.options.sniff.filter,
        start: true
    )
  end
end
end
