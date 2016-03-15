# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
module PacketFu

class PcapHeader
  # Reads a string to populate the object.
  # Conversion from big to little shouldn't be that big of a deal.
  def read(str)
    force_binary(str)
    return self if str.nil?
    str.force_encoding(Encoding::BINARY) if str.respond_to? :force_encoding

    # Handle little endian pcap
    if str[0,4] == self[:magic].to_s
      self[:magic].read str[0,4]
      self[:ver_major].read str[4,2]
      self[:ver_minor].read str[6,2]
      self[:thiszone].read str[8,4]
      self[:sigfigs].read str[12,4]
      self[:snaplen].read str[16,4]
      self[:network].read str[20,4]
    # Handle big endian pcap
    elsif str[0,4] == MAGIC_BIG.to_s
      # Since PcapFile.read uses our endianess, set it to 'big' anyway.
      self[:endian] = :big

      self[:magic].read     str[0,4].reverse
      self[:ver_major].read str[4,2].reverse
      self[:ver_minor].read str[6,2].reverse
      self[:thiszone].read  str[8,4].reverse
      self[:sigfigs].read   str[12,4].reverse
      self[:snaplen].read   str[16,4].reverse
      self[:network].read   str[20,4].reverse
    else
      raise "Incorrect magic for libpcap"
    end
    self
  end
end

end
