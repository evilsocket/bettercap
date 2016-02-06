# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

module BetterCap
module Network
module Protos

class Base
  TYPES = [
      :uint8,
      :uint16,
      :uint32,
      :uint32rev,
      :ip,
      :mac,
      :bytes
  ].freeze

  @@fields = {}

  def self.method_missing(method_name, *arguments, &block)
    type = method_name.to_sym
    name = arguments[0]
    if TYPES.include?(type)
      @@fields[name] = { :type => type, :opts => arguments.length > 1 ? arguments[1] : {} }
      class_eval "attr_accessor :#{name}"
    else
      raise NoMethodError, method_name
    end
  end

  def self.parse( data )
    pkt = self.new

    begin
      offset = 0
      limit  = data.length
      value  = nil

      @@fields.each do |name, info|
        value = nil

        case info[:type]
        when :uint8
          value = data[offset].ord
          offset += 1
        when :uint16
          value = data[offset..offset + 1].unpack('S')[0]
          offset += 2
        when :uint32
          value = data[offset..offset + 3].unpack('L')[0]
          offset += 4
        when :uint32rev
          value = data[offset..offset + 3].reverse.unpack('L')[0]
          offset += 4
        when :ip
          tmp   = data[offset..offset + 3].reverse.unpack('L')[0]
          value = IPAddr.new(tmp, Socket::AF_INET)
          offset += 4
        when :mac
          tmp   = data[offset..offset + 7]
          value = tmp.bytes.map(&(Proc.new {|x| sprintf('%02X',x) })).join(':')
          offset += size( info, 16 )
        when :bytes
          size = size( info, data.length )
          value = data[offset..offset + size - 1].bytes
          offset += size
        end

        pkt.send("#{name}=", value)
      end

    rescue Exception => e
      pkt = nil
    end

    pkt
  end

  def self.size( info, default )
    info[:opts].has_key?(:size) ? info[:opts][:size] : default
  end
end

end
end
end
