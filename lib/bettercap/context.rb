=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

require 'bettercap/error'

module BetterCap
# This class holds global states and data, moreover it exposes high level
# methods to manipulate the program behaviour.
class Context
  # Instance of BetterCap::Options class.
  attr_accessor :options
  # A dictionary containing information about the selected network interface.
  attr_accessor :ifconfig
  # Instance of the current BetterCap::Firewalls class.
  attr_accessor :firewall
  # Network gateway IP address.
  attr_accessor :gateway
  # A list of BetterCap::Target objects which is periodically updated.
  attr_accessor :targets
  # Instance of BetterCap::Discovery::Thread class.
  attr_accessor :discovery
  # A list of BetterCap::Spoofers class instances.
  attr_accessor :spoofer
  # Instance of BetterCap::HTTPD::Server class.
  attr_accessor :httpd
  # Instance of OpenSSL::X509::Certificate class used
  # for the HTTPS transparent proxy.
  attr_accessor :certificate
  # Set to true if the program is running, to false if a shutdown was
  # scheduled by the user which pressed CTRL+C
  attr_accessor :running
  # Timeout for discovery operations.
  attr_reader   :timeout
  # Instance of BetterCap::PacketQueue.
  attr_reader   :packets

  @@instance = nil

  # Return the global instance of the program Context, if the instance
  # was not yet created it will be initialized and returned.
  def self.get
    @@instance ||= self.new
  end

  # Initialize the global context object.
  def initialize
    begin
      iface = Pcap.lookupdev
    rescue Exception => e
      iface = nil
      Logger.debug e.message
    end

    @running         = true
    @timeout         = 5
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
    @discovery       = Discovery::Thread.new self
    @firewall        = Factories::Firewall.get
    @packets         = nil
  end

  # Update the Context state parsing network related informations.
  def update!
    @ifconfig = PacketFu::Utils.ifconfig @options.iface
    @gateway  = Network::Network.get_gateway if @gateway.nil?

    raise BetterCap::Error, "Could not determine IPv4 address of '#{@options.iface}', make sure this interface "\
                            'is active and connected.' if @ifconfig[:ip4_obj].nil?

    raise BetterCap::Error, "Could not detect the gateway address for interface #{@options.iface}, "\
                            'make sure you\'ve specified the correct network interface to use and to have the '\
                            'correct network configuration, this could also happen if bettercap '\
                            'is launched from a virtual environment.' if @gateway.nil? or !Network::Network.is_ip?(@gateway)

    Logger.debug '----- NETWORK INFORMATIONS -----'
    Logger.debug "  network  = #{@ifconfig[:ip4_obj]}"
    Logger.debug "  gateway  = #{@gateway}"
    Logger.debug "  local_ip = #{@ifconfig[:ip_saddr]}\n"
    @ifconfig.each do |key,value|
      Logger.debug "  ifconfig[:#{key}] = #{value}"
    end
    Logger.debug "--------------------------------\n"

    @packets = Network::PacketQueue.new( @ifconfig[:iface], @options.packet_throttle, 4 )
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

  # Apply needed BetterCap::Firewalls::Redirection objects.
  def enable_port_redirection!
    @redirections = @options.to_redirections @ifconfig
    @redirections.each do |r|
      Logger.warn "Redirecting #{r.protocol} traffic from port #{r.src_port} to #{r.dst_address}:#{r.dst_port}"
      @firewall.add_port_redirection( r )
    end
  end

  # Initialize the needed transparent proxies and the processor routined which
  # is needed in order to run proxy modules.
  def create_proxies
    if @options.has_proxy_module?
      Proxy::Module.register_modules

      raise BetterCap::Error, "#{@options.proxy_module} is not a valid bettercap proxy module." if Proxy::Module.modules.empty?
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

  # Stop every running daemon that was started and reset system state.
  def finalize
    @running = false

    # Logger is silent if @running == false
    puts "\nShutting down, hang on ...\n"

    @packets.stop

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
end
