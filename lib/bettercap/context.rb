=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

# this class holds global states & data
require 'bettercap/error'

class Context
  attr_accessor :options, :iface, :ifconfig, :network, :firewall, :gateway,
                :targets, :spoofer, :proxy, :httpd

  @@instance = nil

  def self.get
    @@instance ||= self.new
  end

  def initialize
    @options = {
      :iface => Pcap.lookupdev,
      :spoofer => 'ARP',
      :target => nil,
      :logfile => nil,
      :debug => false,
      :arpcache => false,

      :sniffer => false,
      :sniffer_pcap => nil,
      :parsers => ['*'],
      :local => false,

      :proxy => false,
      :proxy_port => 8080,
      :proxy_module => nil,

      :httpd => false,
      :httpd_port => 8081,
      :httpd_path => './'
    }

    @iface     = nil
    @ifconfig  = nil
    @network   = nil
    @firewall  = nil
    @gateway   = nil
    @targets   = []
    @proxy     = nil
    @spoofer   = nil
    @httpd     = nil

    @discovery_running = false
    @discovery_thread  = nil
  end

  def update_network
    begin
      @iface = PacketFu::Utils.whoami? :iface => @options[:iface]
    rescue SocketError => e
      Logger.debug e.message

      raise BetterCap::Error, "Could not determine IPv4 address of '#{@options[:iface]}' interface, try to specify a different one with the -I argument."
    end

    @firewall = FirewallFactory.get_firewall
    @ifconfig = PacketFu::Utils.ifconfig @options[:iface]
    @network  = @ifconfig[:ip4_obj]
    @gateway  = Network.get_gateway

    raise BetterCap::Error, "Could not determine IPv4 address of '#{@options[:iface]}' interface." unless !@network.nil?

    Logger.debug "network=#{@network} gateway=#{@gateway} local_ip=#{@iface[:ip_saddr]}"
    Logger.debug "IFCONFIG: #{@ifconfig.inspect}"
    Logger.debug "IFACE: #{@iface.inspect}"
  end

  def start_discovery_thread
    @discovery_running = true
    @discovery_thread = Thread.new {
      Logger.info 'Network discovery thread started.'

      while @discovery_running
        empty_list = false

        if @targets.empty? and !@options[:arpcache]
          empty_list = true
          Logger.info 'Searching for alive targets ...'
        end

        @targets = Network.get_alive_targets self

        if empty_list and !@options[:arpcache]
          Logger.info "Collected #{@targets.size} total targets."
          @targets.each do |target|
            Logger.info "  #{target}"
          end
        end
      end
    }
  end

  def stop_discovery_thread
    @discovery_running = false

    if @discovery_thread != nil
      Logger.info 'Stopping network discovery thread ...'

      # I doubt this will ever raise an exception
      begin
        @discovery_thread.join
      rescue
      end
    end
  end

  def finalize
    stop_discovery_thread

    # Consider !!@spoofer
    if !@spoofer.nil?
      @spoofer.stop
    end

    if !@proxy.nil?
      @proxy.stop
      @firewall.del_port_redirection( @options[:iface], 'TCP', 80, @iface[:ip_saddr], @options[:proxy_port] )
    end

    if !@firewall.nil?
      @firewall.enable_forwarding(false)
    end

    if !@httpd.nil?
      @httpd.stop
    end
  end
end
