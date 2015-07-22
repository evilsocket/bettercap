=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require_relative '../logger'
require_relative '../factories/parser_factory'
require 'colorize'
require 'packetfu'

class Sniffer
  include PacketFu

  @@parsers = nil

  def self.start( parsers, iface, my_addr, local )
    Logger.info 'Starting sniffer ...'

    @@parsers = ParserFactory.load_by_names(parsers)

    cap = Capture.new(:iface => iface, :start => true)
    cap.stream.each do |p|
      pkt = Packet.parse p
      if not pkt.nil? and pkt.is_ip?
        next if ( pkt.ip_saddr == my_addr or pkt.ip_daddr == my_addr ) and local == false

        @@parsers.each do |parser|
          parser.on_packet pkt
        end
      end
    end
  end
end
