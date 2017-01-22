# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : https://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

module BetterCap
# Parse command line arguments, set options and initialize +Context+
# accordingly.
class Options
  # Core options
  attr_reader :core
  # Spoofing related options.
  attr_reader :spoof
  # Sniffing related options.
  attr_reader :sniff
  # Proxies related options.
  attr_reader :proxies
  # Misc servers related options.
  attr_reader :servers

  # Create a BetterCap::Options class instance using the specified network interface.
  def initialize( iface )
    @core    = CoreOptions.new iface
    @spoof   = SpoofOptions.new
    @sniff   = SniffOptions.new
    @proxies = ProxyOptions.new
    @servers = ServerOptions.new
  end

  # Initialize the BetterCap::Context, parse command line arguments and update program
  # state accordingly.
  # Will rise a BetterCap::Error if errors occurred.
  def self.parse!
    ctx = Context.get

    OptionParser.new do |opts|
      opts.version = BetterCap::VERSION
      opts.banner = "Usage: bettercap [options]"

      ctx.options.core.parse!( ctx, opts )
      ctx.options.spoof.parse!( ctx, opts )
      ctx.options.sniff.parse!( ctx, opts )
      ctx.options.proxies.parse!( ctx, opts )
      ctx.options.servers.parse!( ctx, opts )

    end.parse!

    # Initialize logging system.
    Logger.init( ctx )

    if ctx.options.core.check_updates
      UpdateChecker.check
      exit
    end

    # Validate options.
    ctx.options.validate!( ctx )
    # Load firewall instance, network interface informations and detect the
    # gateway address.
    ctx.update!

    ctx
  end

  def validate!( ctx )
    @core.validate!
    @proxies.validate!( ctx )
    # Print starting message.
    starting_message
  end

  def need_gateway?
    ( @core.discovery? or @spoof.enabled? )
  end

  # Helper method to create a Firewalls::Redirection object.
  def redir( address, port, to, proto = 'TCP' )
    Firewalls::Redirection.new( @core.iface, proto, nil, port, address, to )
  end

  # Helper method to create a Firewalls::Redirection object for a single address ( +from+ ).
  def redir_single( from, address, port, to, proto = 'TCP' )
    Firewalls::Redirection.new( @core.iface, proto, from, port, address, to )
  end

  # Create a list of BetterCap::Firewalls::Redirection objects which are needed
  # given the specified command line arguments.
  def get_redirections iface
    redirections = []

    if @servers.dnsd or @proxies.sslstrip?
      redirections << redir( iface.ip, 53, @servers.dnsd_port )
      redirections << redir( iface.ip, 53, @servers.dnsd_port, 'UDP' )
    end

    if @proxies.proxy
      @proxies.http_ports.each do |port|
        if @proxies.proxy_upstream_address.nil?
          redirections << redir( iface.ip, port, @proxies.proxy_port )
        else
          redirections << redir_single( @proxies.proxy_upstream_address, iface.ip, port, @proxies.proxy_port )
        end
      end
    end

    if @proxies.proxy_https
      @proxies.https_ports.each do |port|
        if @proxies.proxy_upstream_address.nil?
          redirections << redir( iface.ip, port, @proxies.proxy_https_port )
        else
          redirections << redir_single( @proxies.proxy_upstream_address, iface.ip, port, @proxies.proxy_port )
        end
      end
    end

    if @proxies.tcp_proxy
      redirections << redir_single( @proxies.tcp_proxy_upstream_address, iface.ip, @proxies.tcp_proxy_upstream_port, @proxies.tcp_proxy_port )
    end

    if @proxies.udp_proxy
      redirections << redir_single( @proxies.udp_proxy_upstream_address, iface.ip, @proxies.udp_proxy_upstream_port, @proxies.udp_proxy_port, 'UDP' )
    end

    if @proxies.custom_proxy
      @proxies.http_ports.each do |port|
        redirections << redir( @proxies.custom_proxy, port, @proxies.custom_proxy_port )
      end
    end

    if @proxies.custom_https_proxy
      @proxies.https_ports.each do |port|
        redirections << redir( @proxies.custom_https_proxy, port, @proxies.custom_https_proxy_port )
      end
    end

    @proxies.custom_redirections.each do |r|
      redirections << redir( iface.ip, r[:from], r[:to], r[:proto] )
    end

    redirections
  end

  # Print the starting status message.
  def starting_message
    on     = '✔'.green
    off    = '✘'.red
    status = {
      'spoofing'    => ( @spoof.enabled?  ? on : off ),
      'discovery'   => ( @core.discovery? ? on : off ),
      'sniffer'     => ( @sniff.enabled?  ? on : off ),
      'tcp-proxy'   => ( @proxies.tcp_proxy ? on : off ),
      'udp-proxy'   => ( @proxies.udp_proxy ? on : off ),
      'http-proxy'  => ( @proxies.proxy ? on : off ),
      'https-proxy' => ( @proxies.proxy_https ? on : off ),
      'sslstrip'    => ( @proxies.sslstrip? ? on : off ),
      'http-server' => ( @servers.httpd ? on : off ),
      'dns-server'  => ( (@proxies.sslstrip? or @servers.dnsd) ? on : off )
    }

    msg = "Starting [ "
    status.each do |k,v|
      msg += "#{k}:#{v} "
    end
    msg += "] ...\n\n"

    Logger.info msg
  end
end
end
