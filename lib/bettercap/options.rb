=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

class Options
  attr_accessor :gateway,
                :iface,
                :spoofer,
                :half_duplex,
                :target,
                :logfile,
                :debug,
                :arpcache,
                :ignore,
                :sniffer,
                :sniffer_pcap,
                :sniffer_filter,
                :sniffer_src,
                :parsers,
                :local,
                :proxy,
                :proxy_https,
                :proxy_port,
                :proxy_https_port,
                :proxy_pem_file,
                :proxy_module,
                :custom_proxy,
                :custom_proxy_port,
                :custom_https_proxy,
                :custom_https_proxy_port,
                :httpd,
                :httpd_port,
                :httpd_path,
                :check_updates

  def initialize( iface )
    @gateway = nil
    @iface = iface
    @spoofer = 'ARP'
    @half_duplex = false
    @target = nil
    @logfile = nil
    @debug = false
    @arpcache = false

    @ignore = nil

    @sniffer = false
    @sniffer_pcap = nil
    @sniffer_filter = nil
    @sniffer_src = nil
    @parsers = ['*']
    @local = false

    @proxy = false
    @proxy_https = false
    @proxy_port = 8080
    @proxy_https_port = 8083
    @proxy_pem_file = nil
    @proxy_module = nil

    @custom_proxy = nil
    @custom_proxy_port = 8080

    @custom_https_proxy = nil
    @custom_https_proxy_port = 8083

    @httpd = false
    @httpd_port = 8081
    @httpd_path = './'

    @check_updates = false
  end

  def self.parse!( ctx )
    raise BetterCap::Error, 'This software must run as root.' unless Process.uid == 0

    OptionParser.new do |opts|
      opts.banner = "Usage: #{$0} [options]"
      opts.version = BetterCap::VERSION

      opts.on( '-G', '--gateway ADDRESS', 'Manually specify the gateway address, if not specified the current gateway will be retrieved and used. ' ) do |v|
        ctx.options.gateway = v
      end

      opts.on( '-I', '--interface IFACE', 'Network interface name - default: ' + ctx.options.iface.to_s ) do |v|
        ctx.options.iface = v
      end

      opts.on( '-S', '--spoofer NAME', 'Spoofer module to use, available: ' + SpooferFactory.available.join(', ') + ' - default: ' + ctx.options.spoofer ) do |v|
        ctx.options.spoofer = v
      end

      opts.on( '-T', '--target ADDRESS1,ADDRESS2', 'Target IP addresses, if not specified the whole subnet will be targeted.' ) do |v|
        ctx.options.target = v
      end

      opts.on( '--ignore ADDRESS1,ADDRESS2', 'Ignore these addresses if found while searching for targets.' ) do |v|
        ctx.options.ignore = v
      end

      opts.on( '-O', '--log LOG_FILE', 'Log all messages into a file, if not specified the log messages will be only print into the shell.' ) do |v|
        ctx.options.logfile = v
      end

      opts.on( '-D', '--debug', 'Enable debug logging.' ) do
        ctx.options.debug = true
      end

      opts.on( '-L', '--local', 'Parse packets coming from/to the address of this computer ( NOTE: Will set -X to true ), default to false.' ) do
        ctx.options.local = true
        ctx.options.sniffer = true
      end

      opts.on( '-X', '--sniffer', 'Enable sniffer.' ) do
        ctx.options.sniffer = true
      end

      opts.on( '--sniffer-source FILE', 'Load packets from the specified PCAP file instead of the interface ( will enable sniffer ).' ) do |v|
        ctx.options.sniffer = true
        ctx.options.sniffer_src = File.expand_path v
      end

      opts.on( '--sniffer-pcap FILE', 'Save all packets to the specified PCAP file ( will enable sniffer ).' ) do |v|
        ctx.options.sniffer = true
        ctx.options.sniffer_pcap = File.expand_path v
      end

      opts.on( '--sniffer-filter EXPRESSION', 'Configure the sniffer to use this BPF filter ( will enable sniffer ).' ) do |v|
        ctx.options.sniffer = true
        ctx.options.sniffer_filter = v
      end

      opts.on( '-P', '--parsers PARSERS', 'Comma separated list of packet parsers to enable, "*" for all ( NOTE: Will set -X to true ), available: ' + ParserFactory.available.join(', ') + ' - default: *' ) do |v|
        ctx.options.sniffer = true
        ctx.options.parsers = ParserFactory.from_cmdline(v)
      end

      opts.on( '--no-discovery', 'Do not actively search for hosts, just use the current ARP cache, default to false.' ) do
        ctx.options.arpcache = true
      end

      opts.on( '--no-spoofing', 'Disable spoofing, alias for --spoofer NONE.' ) do
        ctx.options.spoofer = 'NONE'
      end

      opts.on( '--half-duplex', 'Enable half-duplex MITM, this will make bettercap work in those cases when the router is not vulnerable.' ) do
        ctx.options.half_duplex = true
      end

      opts.on( '--proxy', 'Enable HTTP proxy and redirects all HTTP requests to it, default to false.' ) do
        ctx.options.proxy = true
      end

      opts.on( '--proxy-https', 'Enable HTTPS proxy and redirects all HTTPS requests to it, default to false.' ) do
        ctx.options.proxy = true
        ctx.options.proxy_https = true
      end

      opts.on( '--proxy-port PORT', 'Set HTTP proxy port, default to ' + ctx.options.proxy_port.to_s + ' .' ) do |v|
        ctx.options.proxy = true
        ctx.options.proxy_port = v.to_i
      end

      opts.on( '--proxy-https-port PORT', 'Set HTTPS proxy port, default to ' + ctx.options.proxy_https_port.to_s + ' .' ) do |v|
        ctx.options.proxy = true
        ctx.options.proxy_https = true
        ctx.options.proxy_https_port = v.to_i
      end

      opts.on( '--proxy-pem FILE', 'Use a custom PEM certificate file for the HTTPS proxy.' ) do |v|
        ctx.options.proxy = true
        ctx.options.proxy_https = true
        ctx.options.proxy_pem_file = File.expand_path v
      end

      opts.on( '--proxy-module MODULE', 'Ruby proxy module to load.' ) do |v|
        ctx.options.proxy = true
        ctx.options.proxy_module = File.expand_path v
      end

      opts.on( '--custom-proxy ADDRESS', 'Use a custom HTTP upstream proxy instead of the builtin one.' ) do |v|
        ctx.options.custom_proxy = v
      end

      opts.on( '--custom-proxy-port PORT', 'Specify a port for the custom HTTP upstream proxy, default to ' + ctx.options.custom_proxy_port.to_s + ' .' ) do |v|
        ctx.options.custom_proxy_port = v.to_i
      end

      opts.on( '--custom-https-proxy ADDRESS', 'Use a custom HTTPS upstream proxy instead of the builtin one.' ) do |v|
        ctx.options.custom_https_proxy = v
      end

      opts.on( '--custom-https-proxy-port PORT', 'Specify a port for the custom HTTPS upstream proxy, default to ' + ctx.options.custom_https_proxy_port.to_s + ' .' ) do |v|
        ctx.options.custom_https_proxy_port = v.to_i
      end

      opts.on( '--httpd', 'Enable HTTP server, default to false.' ) do
        ctx.options.httpd = true
      end

      opts.on( '--httpd-port PORT', 'Set HTTP server port, default to ' + ctx.options.httpd_port.to_s +  '.' ) do |v|
        ctx.options.httpd = true
        ctx.options.httpd_port = v.to_i
      end

      opts.on( '--httpd-path PATH', 'Set HTTP server path, default to ' + ctx.options.httpd_path +  '.' ) do |v|
        ctx.options.httpd = true
        ctx.options.httpd_path = v
      end

      opts.on( '--check-updates', 'Will check if any update is available and then exit.' ) do
        ctx.options.check_updates = true
      end

      opts.on('-h', '--help', 'Display the available options.') do
        puts opts
        puts "\nFor examples & docs please visit " + "http://bettercap.org/docs/".bold
        exit
      end
    end.parse!

    if ctx.options.check_updates
      error_policy = lambda { |e|
        Logger.error("Could not check for udpates: #{e.message}")
      }

      ctx.check_updates(error_policy)
      exit
    end

    raise BetterCap::Error, 'No default interface found, please specify one with the -I argument.' unless !ctx.options.iface.nil?

    Logger.debug_enabled = true unless !ctx.options.debug
    Logger.logfile       = ctx.options.logfile

    unless ctx.options.gateway.nil?
      raise BetterCap::Error, "Invalid gateway" if !Network.is_ip?(ctx.options.gateway)
      ctx.gateway = ctx.options.gateway
      Logger.info("Targetting manual gateway #{ctx.gateway}")
    end
  end

  def should_discover_hosts?
    !@arpcache
  end

  def has_proxy_module?
    !@proxy_module.nil?
  end

  def has_spoofer?
    @spoofer == 'NONE' or @spoofer == 'none'
  end

  def has_http_sniffer_enabled?
    @sniffer and ( @parsers.include?'*' or @parsers.include?'URL' )
  end

  def ignore_ip?(ip)
    !@ignore.nil? and @ignore.include?(ip)
  end

  def ignore=(value)
    @ignore = value.split(",")
    valid = @ignore.select { |target| Network.is_ip?(target) }

    raise BetterCap::Error, "Invalid ignore addresses specified." if valid.empty?

    invalid = @ignore - valid
    invalid.each do |target|
      Logger.warn "Not a valid address: #{target}"
    end

    @ignore = valid

    Logger.warn "Ignoring #{valid.join(", ")} ."
  end

  def custom_proxy=(value)
    @custom_proxy = value
    raise BetterCap::Error, 'Invalid custom HTTP upstream proxy address specified.' unless Network.is_ip? @custom_proxy
  end

  def custom_https_proxy=(value)
    @custom_https_proxy = value
    raise BetterCap::Error, 'Invalid custom HTTPS upstream proxy address specified.' unless Network.is_ip? @custom_https_proxy
  end

  def to_targets
    targets = @target.split(",")
    valid_targets = targets.select { |target| Network.is_ip?(target) }

    raise BetterCap::Error, "Invalid target" if valid_targets.empty?

    invalid_targets = targets - valid_targets
    invalid_targets.each do |target|
      Logger.warn "Invalid target #{target}"
    end

    valid_targets.map { |target| Target.new(target) }
  end

  def to_spoofers
    spoofers = []
    spoofer_modules_names = @spoofer.split(",")
    spoofer_modules_names.each do |module_name|
      spoofers << SpooferFactory.get_by_name( module_name )
    end
    spoofers
  end

  def to_redirections ifconfig
    redirections = []

    if @proxy
      redirections << Redirection.new( @iface,
                                       'TCP',
                                       80,
                                       ifconfig[:ip_saddr],
                                       @proxy_port )
    end

    if @proxy_https
      redirections << Redirection.new( @iface,
                                       'TCP',
                                       443,
                                       ifconfig[:ip_saddr],
                                       @proxy_https_port )
    end

    if @custom_proxy
      redirections << Redirection.new( @iface,
                                       'TCP',
                                       80,
                                       @custom_proxy,
                                       @custom_proxy_port )
    end

    if @custom_https_proxy
      redirections << Redirection.new( @iface,
                                       'TCP',
                                       443,
                                       @custom_https_proxy,
                                       @custom_https_proxy_port )
    end

    redirections
  end
end
