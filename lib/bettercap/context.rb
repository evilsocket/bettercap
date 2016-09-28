# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

module BetterCap
# This class holds global states and data, moreover it exposes high level
# methods to manipulate the program behaviour.
class Context
  # Instance of BetterCap::Options class.
  attr_accessor :options
  # Instance of the current BetterCap::Firewalls class.
  attr_accessor :firewall
  # Local interface ( as an instance of BetterCap::Network::Target ).
  attr_accessor :iface
  # Network gateway ( as an instance of BetterCap::Network::Target ).
  attr_accessor :gateway
  # A list of BetterCap::Target objects which is periodically updated.
  attr_accessor :targets
  # Instance of BetterCap::Discovery::Thread class.
  attr_accessor :discovery
  # A list of BetterCap::Spoofers class instances.
  attr_accessor :spoofer
  # Instance of BetterCap::Network::Servers::HTTPD class.
  attr_accessor :httpd
  # Instance of BetterCap::Network::Servers::DNSD class.
  attr_accessor :dnsd
  # Set to true if the program is running, to false if a shutdown was
  # scheduled by the user which pressed CTRL+C
  attr_accessor :running
  # Timeout for discovery operations.
  attr_reader   :timeout
  # Instance of BetterCap::PacketQueue.
  attr_reader   :packets
  # Precomputed list of possible addresses on the current network.
  attr_reader   :endpoints

  @@instance = nil

  # Return the global instance of the program Context, if the instance
  # was not yet created it will be initialized and returned.
  def self.get
    @@instance ||= self.new
  end

  # Initialize the global context object.
  def initialize
    begin
      iface = PCAPRUB::Pcap.lookupdev
    rescue Exception => e
      iface = nil
      Logger.exception e
    end

    @running      = true
    @timeout      = 5
    @options      = Options.new iface
    @discovery    = Discovery::Thread.new self
    @firewall     = Firewalls::Base.get
    @iface        = nil
    @original_mac = nil
    @gateway      = nil
    @targets      = []
    @spoofer      = nil
    @httpd        = nil
    @dnsd         = nil
    @proxies      = []
    @redirections = []
    @packets      = nil
    @endpoints    = []
  end

  # Update the Context state parsing network related informations.
  def update!
    gw = @options.core.gateway || Network.get_gateway
    raise BetterCap::Error, "Could not detect the gateway address for interface #{@options.core.iface}, "\
                            'make sure you\'ve specified the correct network interface to use and to have the '\
                            'correct network configuration, this could also happen if bettercap '\
                            'is launched from a virtual environment.' unless Network::Validator.is_ip?(gw)

    unless @options.core.use_mac.nil?
      cfg = PacketFu::Utils.ifconfig @options.core.iface
      raise BetterCap::Error, "Could not determine IPv4 address of '#{@options.core.iface}', make sure this interface "\
                              'is active and connected.' if cfg[:ip4_obj].nil?

      @original_mac = Network::Target.normalized_mac(cfg[:eth_saddr])

      Logger.info "Changing interface MAC address to #{@options.core.use_mac}"

      Shell.change_mac( @options.core.iface, @options.core.use_mac )
    end

    cfg = PacketFu::Utils.ifconfig @options.core.iface
    raise BetterCap::Error, "Could not determine IPv4 address of '#{@options.core.iface}', make sure this interface "\
                            'is active and connected.' if cfg[:ip4_obj].nil?

    @gateway = Network::Target.new gw
    @targets = @options.core.targets unless @options.core.targets.nil?
    @iface   = Network::Target.new( cfg[:ip_saddr], cfg[:eth_saddr], cfg[:ip4_obj], cfg[:iface] )
    raise BetterCap::Error, "Could not determine MAC address of '#{@options.core.iface}', make sure this interface "\
                            'is active and connected.' unless Network::Validator::is_mac?(@iface.mac)

    Logger.info "[#{@iface.name.green}] #{@iface.to_s(false)}"

    Logger.debug '----- NETWORK INFORMATIONS -----'
    Logger.debug "  network  = #{@iface.network} ( #{@iface.network.to_range.to_s.split('..').join( ' -> ')} )"
    Logger.debug "  gateway  = #{@gateway.ip}"
    Logger.debug "  local_ip = #{@iface.ip}"
    Logger.debug "--------------------------------\n"

    @packets = Network::PacketQueue.new( @iface.name, @options.core.packet_throttle, 4 )
    # Spoofers need the context network data to be initialized.
    @spoofer = @options.spoof.parse_spoofers

    if @options.core.discovery?
      tstart = Time.now
      Logger.info "[#{'DISCOVERY'.green}] Precomputing list of possible endpoints, this could take a while depending on your subnet ..."
      net = ip = @iface.network
      # loop each ip in our subnet and push it to the queue
      while net.include?ip
        if ip != @gateway.ip and ip != @iface.ip
          @endpoints << ip
        end
        ip = ip.succ
      end
      tend = Time.now
      Logger.info "[#{'DISCOVERY'.green}] Done in #{(tend - tstart) * 1000.0} ms"
    end
  end

  # Find a target given its +ip+ and +mac+ addresses inside the #targets
  # list, if not found return nil.
  def find_target ip, mac
    @targets.each do |target|
      if target.equals?(ip,mac)
        return target
      end
    end
    nil
  end

  # Start everything!
  def start!
    # Start targets auto discovery.
    @discovery.start

    # Start network spoofers if any.
    @spoofer.each do |spoofer|
      spoofer.start
    end

    # Start proxies and setup port redirection.
    if @options.proxies.any?
      if ( @options.proxies.proxy or @options.proxies.proxy_https ) and @options.sniff.enabled?('URL')
        BetterCap::Logger.warn "WARNING: Both HTTP transparent proxy and URL parser are enabled, you're gonna see duplicated logs."
      end
      create_proxies!
    end

    enable_port_redirection!

    create_servers!

    # Start network sniffer.
    if @options.sniff.enabled?
      Sniffer.start self
    elsif @options.spoof.enabled? and !@options.proxies.any?
      Logger.warn 'WARNING: Sniffer module was NOT enabled ( -X argument ), this '\
                  'will cause the MITM to run but no data to be collected.'
    end
  end

  # Stop every running daemon that was started and reset system state.
  def finalize
    @running = false

    # Logger is silent if @running == false
    puts "\nShutting down, hang on ...\n"

    Logger.debug 'Stopping target discovery manager ...'
    @discovery.stop

    Logger.debug 'Stopping spoofers ...'
    @spoofer.each do |spoofer|
      spoofer.stop
    end

    # Spoofer might be sending some last packets to restore the targets,
    # the packet queue must be stopped here.
    @packets.stop

    Logger.debug 'Stopping proxies ...'
    @proxies.each do |proxy|
      proxy.stop
    end

    Logger.debug 'Disabling port redirections ...'
    @redirections.each do |r|
      @firewall.del_port_redirection( r )
    end

    Logger.debug 'Restoring firewall state ...'
    @firewall.restore

    @dnsd.stop unless @dnsd.nil?
    @httpd.stop unless @httpd.nil?

    Shell.ifconfig( "#{@options.core.iface} ether #{@original_mac}") unless @original_mac.nil?
  end

  private

  # Apply needed BetterCap::Firewalls::Redirection objects.
  def enable_port_redirection!
    @redirections = @options.get_redirections(@iface)
    @redirections.each do |r|
      Logger.debug "Redirecting #{r.protocol} traffic from #{r.src_address.nil? ? '*' : r.src_address}:#{r.src_port} to #{r.dst_address}:#{r.dst_port}"
      @firewall.add_port_redirection( r )
    end
  end

  # Initialize the needed transparent proxies and the processor routined which
  # is needed in order to run proxy modules.
  def create_proxies!
    if @options.proxies.has_proxy_module?
      Proxy::HTTP::Module.register_modules
      raise BetterCap::Error, "#{@options.proxies.proxy_module} is not a valid bettercap proxy module." if Proxy::HTTP::Module.modules.empty?
    end

    # create HTTP proxy
    if @options.proxies.proxy
      @proxies << Proxy::HTTP::Proxy.new( @iface.ip, @options.proxies.proxy_port, false )
    end

    # create HTTPS proxy
    if @options.proxies.proxy_https
      @proxies << Proxy::HTTP::Proxy.new( @iface.ip, @options.proxies.proxy_https_port, true )
    end

    # create TCP proxy
    if @options.proxies.tcp_proxy
      @proxies << Proxy::TCP::Proxy.new( @iface.ip, @options.proxies.tcp_proxy_port, @options.proxies.tcp_proxy_upstream_address, @options.proxies.tcp_proxy_upstream_port )
    end

    @proxies.each do |proxy|
      proxy.start
    end
  end

  # Initialize and start the needed servers.
  def create_servers!
    # Start local DNS server.
    if @options.servers.dnsd
      Logger.warn "Starting DNS server with spoofing disabled, bettercap will only reply to local DNS queries." unless @options.spoof.enabled?

      @dnsd = Network::Servers::DNSD.new( @options.servers.dnsd_file, @iface.ip, @options.servers.dnsd_port )
      @dnsd.start
    end

    # Start local HTTP server.
    if @options.servers.httpd
      @httpd = Network::Servers::HTTPD.new( @options.servers.httpd_port, @options.servers.httpd_path )
      @httpd.start
    end
  end

end
end
