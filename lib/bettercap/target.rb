=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require 'bettercap/logger'
require 'socket'

module BetterCap
class Target
    attr_accessor :ip, :mac, :vendor, :hostname, :ip_refresh

    NBNS_TIMEOUT = 30
    NBNS_PORT    = 137
    NBNS_BUFSIZE = 65536
    NBNS_REQUEST = "\x82\x28\x0\x0\x0\x1\x0\x0\x0\x0\x0\x0\x20\x43\x4B\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x0\x0\x21\x0\x1"

    @@prefixes = nil

    def initialize( ip, mac=nil )
      if Network.is_ip?(ip)
        @ip = ip
        @ip_refresh = false
      else
        @ip         = nil
        mac         = ip
        @ip_refresh = true
      end

      @mac      = Target.normalized_mac(mac) unless mac.nil?
      @vendor   = Target.lookup_vendor(@mac) unless mac.nil?
      @hostname = nil
      @resolver = Thread.new { resolve! } unless Context.get.options.no_target_nbns or @ip.nil?
    end

    def sortable_ip
      @ip.split('.').inject(0) {|total,value| (total << 8 ) + value.to_i}
    end

    def mac=(value)
      @mac = Target.normalized_mac(value)
      @vendor = Target.lookup_vendor(@mac) if not @mac.nil?
    end

    def to_s
      s = sprintf( '%-15s : %-17s', if @ip.nil? then '???' else @ip end, @mac )
      s += " / #{@hostname}" unless @hostname.nil?
      s += if @vendor.nil? then " ( ??? )" else " ( #{@vendor} )" end
      s
    end

    def to_s_compact
      if @hostname
        "#{@hostname}/#{@ip}"
      else
        @ip
      end
    end

    def equals?(ip, mac)
      # compare by ip
      if mac.nil?
        return ( @ip == ip )
      # compare by mac
      elsif !@mac.nil? and ( @mac == mac )
        Logger.info "Found IP #{ip} for target #{@mac}!"
        @ip = ip
        return true
      end
      false
    end

    def self.normalized_mac(v)
      v.split(':').map { |e| if e.size == 2 then e.upcase else "0#{e.upcase}" end }.join(':')
    end

private

    def resolve!
      resp, sock = nil, nil
      begin
        sock = UDPSocket.open
        sock.send( NBNS_REQUEST, 0, @ip, NBNS_PORT )
        resp = if select([sock], nil, nil, NBNS_TIMEOUT)
          sock.recvfrom(NBNS_BUFSIZE)
        end
        if resp
          @hostname = parse_nbns_response resp
          Logger.info "Found NetBIOS name '#{@hostname}' for address #{@ip}"
        end
      rescue Exception => e
        Logger.debug e
      ensure
        sock.close if sock
      end
    end

    def parse_nbns_response resp
      resp[0][57,15].to_s.strip
    end

    def self.lookup_vendor( mac )
      if @@prefixes == nil
        Logger.debug 'Preloading hardware vendor prefixes ...'

        @@prefixes = {}
        filename = File.dirname(__FILE__) + '/hw-prefixes'
        File.open( filename ).each do |line|
          if line =~ /^([A-F0-9]{6})\s(.+)$/
            @@prefixes[$1] = $2
          end
        end
      end

      @@prefixes[ mac.split(':')[0,3].join('').upcase ]
    end
end
end
