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
                :targets, :spoofer, :httpd,
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

    @options           = Options.new iface
    @ifconfig          = nil
    @network           = nil
    @firewall          = nil
    @gateway           = nil
    @targets           = []
    @proxy_processor   = nil
    @spoofer           = nil
    @httpd             = nil
    @certificate       = nil
    @proxies           = []
    @redirections      = []
    @discovery_running = false
    @discovery_thread  = nil
  end

  def check_updates(error_policy = ->{ raise })
    ver = get_latest_version

    case ver
    when BetterCap::VERSION
      Logger.info 'You are running the latest version.'
    else
      Logger.warn "New version '#{ver}' available!"
    end
  rescue Exception => e
    error_policy.call(e)
  end

  def get_latest_version
    Logger.info 'Checking for updates ...'

    api = URI('https://rubygems.org/api/v1/versions/bettercap/latest.json')
    response = Net::HTTP.get_response(api)

    case response
    when Net::HTTPSuccess
      json = JSON.parse(response.body)
    else
      raise response.message
    end

    return json['version']
  end

  def update_network
    @firewall = FirewallFactory.get_firewall
    @ifconfig = PacketFu::Utils.ifconfig @options.iface
    @network  = @ifconfig[:ip4_obj]
    @gateway  = Network.get_gateway if @gateway.nil?

    raise BetterCap::Error, "Could not determine IPv4 address of '#{@options.iface}' interface." unless !@network.nil?

    Logger.debug "network=#{@network} gateway=#{@gateway} local_ip=#{@ifconfig[:ip_saddr]}"
    Logger.debug "IFCONFIG: #{@ifconfig.inspect}"
  end

  def start_discovery_thread
    @discovery_running = true
    @discovery_thread = Thread.new {
      Logger.info( 'Network discovery thread started.' ) unless @options.arpcache

      while @discovery_running
        empty_list = false

        if @targets.empty? and @options.should_discover_hosts?
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

        if empty_list and @options.should_discover_hosts?
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
      Logger.info( 'Stopping network discovery thread ...' ) unless @options.arpcache

      begin
        @discovery_thread.exit
      rescue
      end
    end
  end

  def enable_port_redirection
    @redirections = @options.to_redirections @ifconfig
    @redirections.each do |r|
      Logger.warn "Redirecting #{r.protocol} traffic from port #{r.src_port} to #{r.dst_address}:#{r.dst_port}"

      @firewall.add_port_redirection( r.interface, r.protocol, r.src_port, r.dst_address, r.dst_port )
    end
  end

  def disable_port_redirection
    @redirections.each do |r|
      Logger.debug "Removing #{r.protocol} port redirect from port #{r.src_port} to #{r.dst_address}:#{r.dst_port}"

      @firewall.del_port_redirection( r.interface, r.protocol, r.src_port, r.dst_address, r.dst_port )
    end

    @redirections = []
  end

  def create_proxies
    if @options.has_proxy_module?
      require @options.proxy_module

      Proxy::Module.register_modules

      raise BetterCap::Error, "#{@options.proxy_module} is not a valid bettercap proxy module." unless !Proxy::Module.modules.empty?
    end

    @proxy_processor = Proc.new do |request,response|
      if Proxy::Module.modules.empty?
        Logger.warn 'WARNING: No proxy module loaded, skipping request.'
      else
        # loop each loaded module and execute if enabled
        Proxy::Module.modules.each do |mod|
          if mod.enabled?
            # we need to save the original response in case something
            # in the module will go wrong
            original = response

            begin
              mod.on_request request, response
            rescue Exception => e
              Logger.warn "Error with proxy module: #{e.message}"
              response = original
            end
          end
        end
      end
    end

    # create HTTP proxy
    @proxies << Proxy::Proxy.new( @ifconfig[:ip_saddr], @options.proxy_port, false, @proxy_processor )
    # create HTTPS proxy
    if @options.proxy_https
      # We're not acting as a normal HTTPS proxy, thus we're not
      # able to handle CONNECT requests, thus we don't know the
      # hostname the client is going to connect to.
      # We can only use a self signed certificate.
      if @options.proxy_pem_file.nil?
        @certificate = Proxy::CertStore.get_selfsigned
      else
        @certificate = Proxy::CertStore.from_file @options.proxy_pem_file
      end

      @proxies << Proxy::Proxy.new( @ifconfig[:ip_saddr], @options.proxy_https_port, true, @proxy_processor )
    end

    @proxies.each do |proxy|
      proxy.start
    end
  end

  def finalize
    stop_discovery_thread

    if !@spoofer.nil? and @spoofer.length != 0
      @spoofer.each do |itr|
        itr.stop
      end
    end

    @proxies.each do |proxy|
      proxy.stop
    end

    disable_port_redirection

    if !@firewall.nil?
      @firewall.restore
    end

    if !@httpd.nil?
      @httpd.stop
    end
  end
end
