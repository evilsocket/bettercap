=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require_relative 'logger'
require_relative 'shell'
require_relative 'target'
require_relative 'factories/firewall_factory'

class Network

  def Network.is_ip?(ip)
    if /\A(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})\Z/ =~ ip
      return $~.captures.all? {|i| i.to_i < 256}
    end
    false
  end

  def Network.get_gateway
    out = Shell.execute("netstat -nr").split(/\n/).select {|n| n =~ /UG/ }
    gw = out.first.split[1]

    raise "Could not detect gateway address" unless is_ip?(gw)
    gw
  end

  # FIXME: This should be done with PacketFu
  def Network.get_alive_targets( iface, gw_ip, local_ip, timeout = 5 )
    Logger.info( "Searching for alive targets ..." )
    
    FirewallFactory.get_firewall.enable_icmp_bcast(true)
      
    if RUBY_PLATFORM =~ /darwin/
      ping = Shell.execute("ping -i #{timeout} -c 2 255.255.255.255")
    elsif RUBY_PLATFORM =~ /linux/      
      ping = Shell.execute("ping -i #{timeout} -c 2 -b 255.255.255.255")
    else
      raise "Unsupported operating system"
    end

    arp     = Shell.execute("arp -a")
    targets = []

    arp.split("\n").each do |line|
      if line =~ /[^\s]+\s+\(([0-9\.]+)\)\s+at\s+([a-f0-9:]+).+#{iface}.*/i
        if $1 != gw_ip and $1 != local_ip and $2 != "ff:ff:ff:ff:ff:ff"
          target = Target.new( $1, $2 )
          targets << target
          Logger.info "  #{target}"
        end
      end
    end

    targets
  end

=begin
  FIXME:

  Apparently on Mac OSX the gem pcaprub ( or libpcap itself ) has
  a bug, so we can't use 'PacketFu::Utils::arp' since the funtion
  it's using:

  if cap.save > 0
    ...
  end

  won't catch anything, instead we're using cap.stream.each.
=end
  def Network.get_hw_address( iface, ip_address, attempts = 2 )
    hw_address = nil

    attempts.times do
      arp_pkt = PacketFu::ARPPacket.new

      arp_pkt.eth_saddr     = arp_pkt.arp_saddr_mac = iface[:eth_saddr]
      arp_pkt.eth_daddr     = "ff:ff:ff:ff:ff:ff"
      arp_pkt.arp_daddr_mac = "00:00:00:00:00:00"
      arp_pkt.arp_saddr_ip  = iface[:ip_saddr]
      arp_pkt.arp_daddr_ip  = ip_address

      cap_thread = Thread.new do
        target_mac = nil
        cap = PacketFu::Capture.new(
          :iface => iface[:iface],
          :start => true,
          :filter => "arp src #{ip_address} and ether dst #{arp_pkt.eth_saddr}"
        )
        arp_pkt.to_w(iface[:iface])

        timeout = 0

        while target_mac.nil? && timeout <= 5
          cap.stream.each do |p|
            arp_response = PacketFu::Packet.parse(p)
            target_mac = arp_response.arp_saddr_mac if arp_response.arp_saddr_ip == ip_address

            break unless target_mac.nil?
          end

          timeout += 0.1

          Logger.debug "Retrying ..."
          sleep 0.1
        end
        target_mac
      end
      hw_address = cap_thread.value

      break unless hw_address.nil?
    end

    hw_address
  end
end
