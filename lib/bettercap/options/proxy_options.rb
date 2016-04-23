# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

module BetterCap

class ProxyOptions
  # If true, HTTP transparent proxy will be enabled.
  attr_accessor :proxy
  # If true, HTTPS transparent proxy will be enabled.
  attr_accessor :proxy_https
  # If set, only this address will be redirected to the HTTP(S) proxiy.
  attr_accessor :proxy_upstream_address
  # HTTP proxy port.
  attr_accessor :proxy_port
  # List of HTTP ports, [ 80 ] by default.
  attr_accessor :http_ports
  # HTTPS proxy port.
  attr_accessor :proxy_https_port
  # List of HTTPS ports, [ 443 ] by default.
  attr_accessor :https_ports
  # File name of the PEM certificate to use for the HTTPS proxy.
  attr_accessor :proxy_pem_file
  # File name of the transparent proxy module to load.
  attr_accessor :proxy_module
  # If true, sslstrip is enabled.
  attr_accessor :sslstrip
  # If true, direct connections to the IP of this machine will be allowed.
  attr_accessor :allow_local_connections
  # If true, TCP proxy will be enabled.
  attr_accessor :tcp_proxy
  # TCP proxy local port.
  attr_accessor :tcp_proxy_port
  # TCP proxy upstream server address.
  attr_accessor :tcp_proxy_upstream_address
  # TCP proxy upstream server port.
  attr_accessor :tcp_proxy_upstream_port
  # TCP proxy module to load.
  attr_accessor :tcp_proxy_module
  # Custom HTTP transparent proxy address.
  attr_accessor :custom_proxy
  # Custom HTTP transparent proxy port.
  attr_accessor :custom_proxy_port
  # Custom HTTPS transparent proxy address.
  attr_accessor :custom_https_proxy
  # Custom HTTPS transparent proxy port.
  attr_accessor :custom_https_proxy_port
  # Custom list of redirections.
  attr_accessor :custom_redirections

  def initialize
    @http_ports = [ 80 ]
    @https_ports = [ 443 ]
    @proxy = false
    @proxy_https = false
    @proxy_upstream_address = nil
    @proxy_port = 8080
    @proxy_https_port = 8083
    @proxy_pem_file = nil
    @proxy_module = nil
    @sslstrip = true
    @allow_local_connections = false

    @tcp_proxy = false
    @tcp_proxy_port = 2222
    @tcp_proxy_upstream_address = nil
    @tcp_proxy_upstream_port = nil
    @tcp_proxy_module = nil

    @custom_proxy = nil
    @custom_proxy_port = 8080

    @custom_https_proxy = nil
    @custom_https_proxy_port = 8083

    @custom_redirections = []
  end

  def parse!( ctx, opts )
    opts.separator ""
    opts.separator "PROXYING:".bold
    opts.separator ""

    opts.separator ""
    opts.separator "  TCP:"
    opts.separator ""

    opts.on( '--tcp-proxy', 'Enable TCP proxy ( requires other --tcp-proxy-* options to be specified ).' ) do
      @tcp_proxy = true
    end

    opts.on( '--tcp-proxy-module MODULE', "Ruby TCP proxy module to load." ) do |v|
      @tcp_proxy_module = File.expand_path(v)
      Proxy::TCP::Module.load( @tcp_proxy_module )
    end

    opts.on( '--tcp-proxy-port PORT', "Set local TCP proxy port, default to #{@tcp_proxy_port.to_s.yellow} ." ) do |v|
      raise BetterCap::Error, "Invalid port '#{v}' specified." unless Network::Validator.is_valid_port?(v)
      @tcp_proxy      = true
      @tcp_proxy_port = v.to_i
    end

    opts.on( '--tcp-proxy-upstream ADDRESS:PORT', 'Set TCP proxy upstream server address and port.' ) do |v|
      if v =~ /^(.+):(\d+)$/
        address = $1
        port    = $2
      else
        raise BetterCap::Error, "Invalid address and port specified, the correct syntax is ADDRESS:PORT ( i.e. 192.168.1.2:22 )."
      end

      address, port = validate_address address, port

      @tcp_proxy                  = true
      @tcp_proxy_upstream_address = address
      @tcp_proxy_upstream_port    = port.to_i
    end

    opts.on( '--tcp-proxy-upstream-address ADDRESS', 'Set TCP proxy upstream server address.' ) do |v|
      v, _ = validate_address v

      @tcp_proxy                  = true
      @tcp_proxy_upstream_address = v
    end

    opts.on( '--tcp-proxy-upstream-port PORT', 'Set TCP proxy upstream server port.' ) do |v|
      raise BetterCap::Error, "Invalid port '#{v}' specified." unless Network::Validator.is_valid_port?(v)
      @tcp_proxy               = true
      @tcp_proxy_upstream_port = v.to_i
    end

    opts.separator "  HTTP:"
    opts.separator ""

    opts.on( '--proxy', "Enable HTTP proxy and redirects all HTTP requests to it, default to #{'false'.yellow}." ) do
      @proxy = true
    end

    opts.on( '--proxy-port PORT', "Set HTTP proxy port, default to #{@proxy_port.to_s.yellow}." ) do |v|
      raise BetterCap::Error, "Invalid port '#{v}' specified." unless Network::Validator.is_valid_port?(v)
      @proxy = true
      @proxy_port = v.to_i
    end

    opts.on( '--allow-local-connections', "Allow direct connections to the proxy instance, default to #{@allow_local_connections.to_s.yellow}." ) do |v|
      @proxy = true
      @allow_local_connections = true
    end

    opts.on( '--no-sslstrip', 'Disable SSLStrip.' ) do
      @proxy    = true
      @sslstrip = false
    end

    opts.on( '--proxy-module MODULE', "Ruby proxy module to load, either a custom file or one of the following: #{Proxy::HTTP::Module.available.map{|x| x.yellow}.join(', ')}." ) do |v|
      Proxy::HTTP::Module.load(ctx, opts, v)
      @proxy = true
    end

    opts.on( '--http-ports PORT1,PORT2', "Comma separated list of HTTP ports to redirect to the proxy, default to #{@http_ports.map{|x| x.to_s.yellow }.join(', ')}." ) do |v|
      @http_ports = ProxyOptions.parse_ports( v )
      @proxy      = true
    end

    opts.on( '--proxy-upstream-address ADDRESS', 'If set, only requests coming from this server address will be redirected to the HTTP/HTTPS proxies.' ) do |v|
      v, _ = validate_address v
      @proxy_upstream_address = v
    end

    opts.separator ""
    opts.separator "  HTTPS:"
    opts.separator ""

    opts.on( '--proxy-https', "Enable HTTPS proxy and redirects all HTTPS requests to it, default to #{'false'.yellow}." ) do
      @proxy_https = true
    end

    opts.on( '--proxy-https-port PORT', "Set HTTPS proxy port, default to #{@proxy_https_port.to_s.yellow}." ) do |v|
      raise BetterCap::Error, "Invalid port '#{v}' specified." unless Network::Validator.is_valid_port?(v)
      @proxy_https = true
      @proxy_https_port = v.to_i
    end

    opts.on( '--proxy-pem FILE', "Use a custom PEM CA certificate file for the HTTPS proxy, default to #{Proxy::HTTP::SSL::Authority::DEFAULT.yellow} ." ) do |v|
      @proxy_https = true
      @proxy_pem_file = File.expand_path v
    end

    opts.on( '--https-ports PORT1,PORT2', "Comma separated list of HTTPS ports to redirect to the proxy, default to #{@https_ports.map{|x| x.to_s.yellow }.join(', ')}." ) do |v|
      @https_ports = ProxyOptions.parse_ports( v )
      @proxy_https = true
    end

    opts.separator ""
    opts.separator "  CUSTOM:"
    opts.separator ""

    opts.on( '--custom-proxy ADDRESS', 'Use a custom HTTP upstream proxy instead of the builtin one.' ) do |v|
      parse_custom_proxy!(v)
    end

    opts.on( '--custom-proxy-port PORT', "Specify a port for the custom HTTP upstream proxy, default to #{@custom_proxy_port.to_s.yellow}." ) do |v|
      raise BetterCap::Error, "Invalid port '#{v}' specified." unless Network::Validator.is_valid_port?(v)
      @custom_proxy_port = v.to_i
    end

    opts.on( '--custom-https-proxy ADDRESS', 'Use a custom HTTPS upstream proxy instead of the builtin one.' ) do |v|
      parse_custom_proxy!( v, true )
    end

    opts.on( '--custom-https-proxy-port PORT', "Specify a port for the custom HTTPS upstream proxy, default to #{@custom_https_proxy_port.to_s.yellow}." ) do |v|
      raise BetterCap::Error, "Invalid port '#{v}' specified." unless Network::Validator.is_valid_port?(v)
      @custom_https_proxy_port = v.to_i
    end

    opts.on( '--custom-redirection RULE', "Apply a custom port redirection, the format of the rule is #{'PROTOCOL ORIGINAL_PORT NEW_PORT'.yellow}. For instance #{'TCP 21 2100'.yellow} will redirect all TCP traffic going to port 21, to port 2100." ) do |v|
      parse_redirection!( v )
    end
  end

  def validate!( ctx )
    if @tcp_proxy
      raise BetterCap::Error, "No TCP proxy port specified ( --tcp-proxy-port PORT )." if @tcp_proxy_port.nil?
      raise BetterCap::Error, "No TCP proxy upstream server address specified ( --tcp-proxy-upstream-address ADDRESS )." if @tcp_proxy_upstream_address.nil?
      raise BetterCap::Error, "No TCP proxy upstream server port specified ( --tcp-proxy-upstream-port PORT )." if @tcp_proxy_upstream_port.nil?
    end

    if @proxy and @sslstrip and ctx.options.servers.dnsd
      raise BetterCap::Error, "SSL Stripping and builtin DNS server are mutually exclusive features, " \
                              "either use the --no-sslstrip option or remove the --dns option."
    end

    if has_proxy_module? and ( !@proxy and !@proxy_https )
      raise BetterCap::Error, "A proxy module was specified but none of the HTTP or HTTPS proxies are " \
                              "enabled, specify --proxy or --proxy-https options."
    end

  end

  # Parse a comma separated list of ports and return an array containing only
  # valid ports, raise BetterCap::Error if that array is empty.
  def self.parse_ports(value)
    ports = []
    value.split(",").each do |v|
      v = v.strip.to_i
      if v > 0 and v <= 65535
        ports << v
      end
    end
    raise BetterCap::Error, 'Invalid ports specified.' if ports.empty?
    ports
  end

  # Setter for the #custom_proxy or #custom_https_proxy attribute, will raise a
  # BetterCap::Error if +value+ is not a valid IP address.
  def parse_custom_proxy!(value, https=false)
    raise BetterCap::Error, 'Invalid custom HTTP upstream proxy address specified.' unless Network::Validator.is_ip?(value)
    if https
      @custom_https_proxy = value
    else
      @custom_proxy = value
    end
  end

  # Parse a custom redirection rule.
  def parse_redirection!(rule)
    if rule =~ /^((TCP)|(UDP))\s+(\d+)\s+(\d+)$/i
      @custom_redirections << {
        :proto => $1.upcase,
        :from  => $4.to_i,
        :to    => $5.to_i
      }
    else
      raise BetterCap::Error, 'Invalid custom redirection rule specified.'
    end
  end

  # Return true if a proxy module was specified, otherwise false.
  def has_proxy_module?
    !@proxy_module.nil?
  end

  def sslstrip?
    @proxy and @sslstrip
  end

  def any?
    @proxy or @proxy_https or @tcp_proxy or @custom_proxy
  end

  def validate_address( address, port = nil )
    unless Network::Validator.is_ip?(address)
      begin
        address = IPSocket.getaddress address
      rescue SocketError
        raise BetterCap::Error, "Could not resolve '#{address}' to a valid ip address."
      end
    end

    raise BetterCap::Error, "Invalid port '#{port}' specified." unless port.nil? or Network::Validator.is_valid_port?(port)

    [ address, port ]
  end
end

end
