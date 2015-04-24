=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require_relative 'logger'

class Target
    attr_accessor :ip, :mac, :vendor, :hostname

    @@prefixes = nil

    def initialize( ip, mac )
        @ip = ip
        @mac = mac
        @vendor = Target.lookup_vendor(mac) if not mac.nil?
        @hostname = nil # for future use
    end

    def mac=(value)
        @mac = value
        @vendor = Target.lookup_vendor(@mac) if not @mac.nil?
    end

    def to_s
        "#{@ip} : #{@mac}" + ( @vendor ? " ( #{@vendor} )" : "" )
    end

private

    def self.lookup_vendor( mac )
        if @@prefixes == nil
            Logger.info "Preloading hardware vendor prefixes ..."

            @@prefixes = {}
            filename = File.dirname(__FILE__) + '/hw-prefixes'
            File.open( filename ).each do |line|
                if line =~ /^([A-F0-9]{6})\s(.+)$/
                    @@prefixes[$1] = $2
                end
            end
        end

        @@prefixes[ mac.split(':')[0,3].join("").upcase ]
    end
end
