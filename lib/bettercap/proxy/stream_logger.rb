# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require 'zlib'
require 'stringio'
require 'json'

module BetterCap
# Raw or http streams pretty logging.
class StreamLogger
  @@MAX_REQ_SIZE = 50

  @@CODE_COLORS  = {
    '2' => :green,
    '3' => :light_black,
    '4' => :yellow,
    '5' => :red
  }

  @@services = nil

  # Search for the +addr+ IP address inside the list of collected targets and return
  # its compact string representation ( @see BetterCap::Target#to_s_compact ).
  def self.addr2s( addr, alt = nil )
    ctx = Context.get
    # check for the local address
    return 'local' if addr == ctx.ifconfig[:ip_saddr]
    # is it a known target?
    target = ctx.find_target addr, nil
    return target.to_s_compact unless target.nil?
    # fix 0.0.0.0 if alt argument was specified
    return alt if addr == '0.0.0.0' and !alt.nil?
    # fix broadcast -> *
    return '*' if addr == '255.255.255.255'
    # nothing found, return the address as it is
    addr
  end

  # Given +proto+ and +port+ return the network service name if possible.
  def self.service( proto, port )
    if @@services.nil?
      Logger.info 'Preloading network services ...'

      @@services = { :tcp => {}, :udp => {} }
      filename = File.dirname(__FILE__) + '/../network/services'
      File.open( filename ).each do |line|
        if line =~ /([^\s]+)\s+(\d+)\/([a-z]+).*/i
          @@services[$3.to_sym][$2.to_i] = $1
        end
      end
    end

    if @@services.has_key?(proto) and @@services[proto].has_key?(port)
      @@services[proto][port]
    else
      port
    end
  end

  # Log a raw packet ( +pkt+ ) data +payload+ using the specified +label+.
  def self.log_raw( pkt, label, payload )
    nl    = label.include?("\n") ? "\n" : " "
    label = label.strip
    from  = self.addr2s( pkt.ip_saddr, pkt.eth2s(:src) )
    to    = self.addr2s( pkt.ip_daddr, pkt.eth2s(:dst) )

    if pkt.respond_to?('tcp_dst')
      to += ':' + self.service( :tcp, pkt.tcp_dst ).to_s.light_blue
    elsif pkt.respond_to?('udp_dst')
      to += ':' + self.service( :udp, pkt.udp_dst ).to_s.light_blue
    end

    Logger.raw( "[#{from} > #{to}] [#{label.green}]#{nl}#{payload.strip}" )
  end

  def self.dump_form( request )
    msg = ''
    request.body.split('&').each do |v|
      name, value = v.split('=')
      name ||= ''
      value ||= ''
      msg << "  #{name.blue} : #{URI.unescape(value).yellow}\n"
    end
    msg
  end

  def self.dump_raw( data )
    msg = ''
    data.each_byte do |b|
      msg << ( b.chr =~ /[[:print:]]/ ? b.chr : '.' ).yellow
    end
    msg
  end

  def self.dump_gzip( request )
    msg = ''
    uncompressed = Zlib::GzipReader.new(StringIO.new(request.body)).read
    self.dump_raw( uncompressed )
  end

  def self.dump_json( request )
    obj = JSON.parse( request.body )
    json = JSON.pretty_unparse(obj)
    json.scan( /("[^"]+"):/ ).map { |x| json.gsub!( x[0], x[0].blue )}
    json
  end

  # If +request+ is a complete POST request, this method will log every header
  # and post field with its value.
  def self.log_post( request )
    # the packet could be incomplete
    if request.post? and !request.body.nil? and !request.body.empty?
      msg = "\n[#{'HEADERS'.green}]\n\n"
      request.headers.each do |name,value|
        msg << "  #{name.blue} : #{value.yellow}\n"
      end
      msg << "\n[#{'BODY'.green}]\n\n"

      case request['Content-Type']
      when /application\/x-www-form-urlencoded.*/i
        msg << self.dump_form( request )

      when 'gzip'
        msg << self.dump_gzip( request )

      when 'application/json'
        msg << self.dump_json( request )

      else
        msg << self.dump_raw( request.body )
      end

      Logger.raw "#{msg}\n"
    end
  end

  # Log a HTTP ( HTTPS if +is_https+ is true ) stream performed by the +client+
  # with the +request+ and +response+ most important informations.
  def self.log_http( request, response )
    response_s = "( #{response.content_type} )"
    request_s  = request.to_url( request.post?? nil : @@MAX_REQ_SIZE )
    code       = response.code[0]

    if @@CODE_COLORS.has_key? code
      response_s += " [#{response.code}]".send( @@CODE_COLORS[ code ] )
    else
      response_s += " [#{response.code}]"
    end

    Logger.raw "[#{self.addr2s(request.client)}] #{request.method.light_blue} #{request_s} #{response_s}"
    # Log post body if the POST sniffer is enabled.
    if Context.get.post_sniffer_enabled?
      self.log_post( request )
    end
  end
end
end
