=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require_relative 'logger'
require 'colorize'
require 'packetfu'
include PacketFu

class Sniffer
    def self.start( iface, my_addr )
        cap = Capture.new(:iface => iface, :start => true)
        cap.stream.each do |p|
            pkt = Packet.parse p
            if pkt.is_ip?
                next if pkt.ip_saddr == my_addr or pkt.ip_daddr == my_addr

                puts "#{pkt.ip_saddr} -> #{pkt.ip_daddr} #{pkt.proto.last}"
            end
        end
    end
end
