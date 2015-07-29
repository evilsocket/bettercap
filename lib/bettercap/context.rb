=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

# this class holds global states & data
require 'bettercap/version'
require 'bettercap/error'
require 'net/http'
require 'json'

class Context
  attr_accessor :options, :ifconfig, :network, :firewall, :gateway,
                :targets, :spoofer, :proxy, :https_proxy, :httpd,
                :certificate

  @@instance = nil

  def self.get
    @@instance ||= self.new
  end

  def initialize
    begin
      iface = Pcap.lookupdev
    rescue Exception => e
      iface = nil
      Logger.debug e.message
    end

    @options = {
      iface: iface,
      spoofer: 'ARP',
      target: nil,
      logfile: nil,
      debug: false,
      arpcache: false,

      sniffer: false,
      sniffer_pcap: nil,
      sniffer_filter: nil,
      parsers: ['*'],
      local: false,

      proxy: false,
      proxy_https: false,
      proxy_port: 8080,
      proxy_https_port: 8083,
      proxy_pem_file: nil,
      proxy_module: nil,

      httpd: false,
      httpd_port: 8081,
      httpd_path: './',

      check_updates: false
    }

    @ifconfig    = nil
    @network     = nil
    @firewall    = nil
    @gateway     = nil
    @targets     = []
    @proxy       = nil
    @https_proxy = nil
    @spoofer     = nil
    @httpd       = nil
    @certificate = nil

    @discovery_running = false
    @discovery_thread  = nil
  end

  def check_updates
    Logger.info 'Checking for updates ...'

    api  = URI('https://api.github.com/repos/evilsocket/bettercap/releases/latest')
    body = Net::HTTP.get(api)
    json = JSON.parse(body)

    if json['tag_name'] != BetterCap::VERSION and json['tag_name'] != "v#{BetterCap::VERSION}"
      return json['tag_name']
    end
    nil
  end

  def update_network
    @firewall = FirewallFactory.get_firewall
    @ifconfig = PacketFu::Utils.ifconfig @options[:iface]
    @network  = @ifconfig[:ip4_obj]
    @gateway  = Network.get_gateway

    raise BetterCap::Error, "Could not determine IPv4 address of '#{@options[:iface]}' interface." unless !@network.nil?

    Logger.debug "network=#{@network} gateway=#{@gateway} local_ip=#{@ifconfig[:ip_saddr]}"
    Logger.debug "IFCONFIG: #{@ifconfig.inspect}"
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
        else
          # make sure we don't stress the logging system
          10.times do
            sleep 1
            if !@discovery_running
              break
            end
          end
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

  def enable_port_redirection
    @firewall.add_port_redirection( @options[:iface], 'TCP', 80, @ifconfig[:ip_saddr], @options[:proxy_port] )
    if @options[:proxy_https]
      @firewall.add_port_redirection( @options[:iface], 'TCP', 443, @ifconfig[:ip_saddr], @options[:proxy_https_port] )
    end
  end

  def disable_port_redirection
    @firewall.del_port_redirection( @options[:iface], 'TCP', 80, @ifconfig[:ip_saddr], @options[:proxy_port] )
    if @options[:proxy_https]
      @firewall.del_port_redirection( @options[:iface], 'TCP', 443, @ifconfig[:ip_saddr], @options[:proxy_https_port] )
    end
  end

  def create_proxies
    if not @options[:proxy_module].nil?
      require @options[:proxy_module]

      Proxy::Module.register_modules

      raise BetterCap::Error, "#{@options[:proxy_module]} is not a valid bettercap proxy module." unless !Proxy::Module.modules.empty?
    end

    # create HTTP proxy
    @proxy = Proxy::Proxy.new( @ifconfig[:ip_saddr], @options[:proxy_port], false ) do |request,response|
      if Proxy::Module.modules.empty?
        Logger.warn 'WARNING: No proxy module loaded, skipping request.'
      else
        # loop each loaded module and execute if enabled
        Proxy::Module.modules.each do |mod|
          if mod.enabled?
            mod.on_request request, response
          end
        end
      end
    end

    # create HTTPS proxy
    if @options[:proxy_https]
      # We're not acting as a normal HTTPS proxy, thus we're not
      # able to handle CONNECT requests, thus we don't know the
      # hostname the client is going to connect to.
      # We can only use a self signed certificate.
      if @options[:proxy_pem_file].nil?
        @certificate = Proxy::CertStore.get_selfsigned
      else
        @certificate = Proxy::CertStore.from_file @options[:proxy_pem_file]
      end

      @https_proxy = Proxy::Proxy.new( @ifconfig[:ip_saddr], @options[:proxy_https_port], true ) do |request,response|
        if Proxy::Module.modules.empty?
          Logger.warn 'WARNING: No proxy module loaded, skipping request.'
        else
          # loop each loaded module and execute if enabled
          Proxy::Module.modules.each do |mod|
            if mod.enabled?
              mod.on_request request, response
            end
          end
        end
      end

      @https_proxy.start
    end

    @proxy.start
  end

  def finalize
    stop_discovery_thread

    # Consider !!@spoofer
    if !@spoofer.nil?
      @spoofer.stop
    end

    if !@proxy.nil?
      @proxy.stop
      if !@https_proxy.nil?
        @https_proxy.stop
      end
      disable_port_redirection
    end

    if !@firewall.nil?
      @firewall.restore
    end

    if !@httpd.nil?
      @httpd.stop
    end
  end
end
