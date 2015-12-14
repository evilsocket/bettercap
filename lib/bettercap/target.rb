=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require 'bettercap/logger'
require 'socket'

class Target
    attr_accessor :ip, :mac, :vendor, :hostname

    NBNS_TIMEOUT = 30
    NBNS_PORT    = 137
    NBNS_BUFSIZE = 65536
    NBNS_REQUEST = "\x82\x28\x0\x0\x0\x1\x0\x0\x0\x0\x0\x0\x20\x43\x4B\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x0\x0\x21\x0\x1"

    @@prefixes = nil

    def initialize( ip, mac=nil )
      @ip       = ip
      @mac      = mac
      @vendor   = Target.lookup_vendor(mac) if not mac.nil?
      @hostname = nil
      @resolver = Thread.new { resolve! }
    end

    def mac=(value)
      @mac = value
      @vendor = Target.lookup_vendor(@mac) if not @mac.nil?
    end

    def to_s
      s = @ip
      s += " ( #{@hostname} )" unless @hostname.nil?
      s += " : #{@mac}"
      s += " ( #{@vendor} )" unless @vendor.nil?
      s
    end

    def to_s_compact
      if @hostname
        "#{@hostname}/#{@ip}"
      else
        @ip
      end
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
