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
      :uint16rev,
      :uint24,
      :uint32,
      :uint32rev,
      :ip,
      :mac,
      :bytes,
      :string,
      :stringz
  ].freeze

  def self.method_missing(method_name, *arguments, &block)
    type = method_name.to_sym
    name = arguments[0]
    if TYPES.include?(type)
      unless self.class_variables.include?(:@@fields)
        class_eval "@@fields = {}"
      end

      class_eval "@@fields[:#{name}] = { :type => :#{type}, :opts => #{arguments.length > 1 ? arguments[1] : {}} }"
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

      self.class_variable_get(:@@fields).each do |name, info|
        value = nil

        case info[:type]
        when :uint8
          value = data[offset].ord
          offset += 1

        when :uint16
          value = data[offset..offset + 1].unpack('S')[0]
          offset += 2

        when :uint16rev
          value = data[offset..offset + 1].reverse.unpack('S')[0]
          offset += 2

        when :uint24
          value = data[offset..offset + 2].unpack('S')[0]
          offset += 3

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
          offset += size( info, pkt, 16 )

        when :bytes
          size = size( info, pkt, data.length )
          offset = offset( info, pkt, offset  )

          value = data[offset..offset + size - 1].bytes
          offset += size

        when :string
          size = size( info, pkt, data.length )
          offset = offset( info, pkt, offset  )

          value = data[offset..offset + size - 1].bytes.pack('c*')
          offset += size

        when :stringz
          value = ""
          loop do
            value += data[offset]
            offset += 1
            break if data[offset].ord == 0x00
          end
          offset += 1

        end

        if info[:opts].has_key?(:check)
          check = info[:opts][:check]
          check = check.force_encoding('ASCII-8BIT') if check.respond_to? :force_encoding
          if value != check
            raise "Unexpected value '#{value}', expected '#{check}' ."
          end
        end

        pkt.send("#{name}=", value)
      end

    rescue Exception => e
      #puts e.message
      #puts e.backtrace.join("\n")
      pkt = nil
    end

    pkt
  end

  def self.size( info, pkt, default )
    return default unless info[:opts].has_key?(:size)
    return info[:opts][:size] if info[:opts][:size].is_a?(Integer)
    return pkt.send( info[:opts][:size] )
  end

  def self.offset( info, pkt, default )
    return default unless info[:opts].has_key?(:offset)
    return info[:opts][:offset] if info[:opts][:offset].is_a?(Integer)
    return default + pkt.send( info[:opts][:offset] )
  end
end

end
end
end
