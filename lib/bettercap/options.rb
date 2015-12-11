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
