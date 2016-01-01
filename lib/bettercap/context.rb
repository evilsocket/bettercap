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
  attr_accessor :options, :ifconfig, :firewall, :gateway,
                :targets, :discovery, :spoofer, :httpd,
                :certificate, :running

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

    @running         = true
    @options         = Options.new iface
    @ifconfig        = nil
    @firewall        = nil
    @gateway         = nil
    @targets         = []
    @proxy_processor = nil
    @spoofer         = nil
    @httpd           = nil
    @certificate     = nil
    @proxies         = []
    @redirections    = []
    @discovery       = Discovery.new self
    @firewall        = FirewallFactory.get_firewall
  end

  def update!
    @ifconfig = PacketFu::Utils.ifconfig @options.iface
    @gateway  = Network.get_gateway if @gateway.nil?

    raise BetterCap::Error, "Could not determine IPv4 address of '#{@options.iface}', make sure this interface "\
                            'is active and connected.' if @ifconfig[:ip4_obj].nil?

    raise BetterCap::Error, "Could not detect the gateway address for interface #{@options.iface}, "\
                            'make sure you\'ve specified the correct network interface to use and to have the '\
                            'correct network configuration, this could also happen if bettercap '\
                            'is launched from a virtual environment.' if @gateway.nil? or !Network.is_ip?(@gateway)

    Logger.debug "network=#{@ifconfig[:ip4_obj]} gateway=#{@gateway} local_ip=#{@ifconfig[:ip_saddr]}"
    Logger.debug "IFCONFIG: #{@ifconfig.inspect}"
  end

  def find_target ip, mac
    @targets.each do |target|
      if target.ip == ip && ( mac.nil? || target.mac == mac )
        return target
      end
    end
    nil
  end

  def enable_port_redirection!
    @redirections = @options.to_redirections @ifconfig
    @redirections.each do |r|
      Logger.warn "Redirecting #{r.protocol} traffic from port #{r.src_port} to #{r.dst_address}:#{r.dst_port}"
      @firewall.add_port_redirection( r )
    end
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
    @running = false
    
    Logger.info 'Shutting down, hang on ...'

    Logger.debug 'Stopping target discovery manager ...'
    @discovery.stop

    Logger.debug 'Stopping spoofers ...'
    @spoofer.each do |spoofer|
      spoofer.stop
    end

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

    @httpd.stop unless @httpd.nil?
  end
end
