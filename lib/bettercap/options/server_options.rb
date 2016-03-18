# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

module BetterCap

class ServerOptions
  # If true, BetterCap::Network::Servers::HTTPD will be enabled.
  attr_accessor :httpd
  # The port to bind HTTP server to.
  attr_accessor :httpd_port
  # Web root of the HTTP server.
  attr_accessor :httpd_path
  # If true, BetterCap::Network::Servers::DNSD will be enabled.
  attr_accessor :dnsd
  # The port to bind DNS server to.
  attr_accessor :dnsd_port
  # The host resolution file to use with the DNS server.
  attr_accessor :dnsd_file

  def initialize
    @httpd      = false
    @httpd_port = 8081
    @httpd_path = './'
    @dnsd       = false
    @dnsd_port  = 5300
    @dnsd_file  = nil
  end

  def parse!( ctx, opts )
    opts.separator ""
    opts.separator "SERVERS:".bold
    opts.separator ""

    opts.on( '--httpd', "Enable HTTP server, default to #{'false'.yellow}." ) do
      @httpd = true
    end

    opts.on( '--httpd-port PORT', "Set HTTP server port, default to #{@httpd_port.to_s.yellow}." ) do |v|
      raise BetterCap::Error, "Invalid port '#{v}' specified." unless Network::Validator.is_valid_port?(v)
      @httpd = true
      @httpd_port = v.to_i
    end

    opts.on( '--httpd-path PATH', "Set HTTP server path, default to #{@httpd_path.yellow} ." ) do |v|
      @httpd = true
      @httpd_path = v
    end

    opts.on( '--dns FILE', 'Enable DNS server and use this file as a hosts resolution table.' ) do |v|
      @dnsd      = true
      @dnsd_file = File.expand_path v
    end

    opts.on( '--dns-port PORT', "Set DNS server port, default to #{@dnsd_port.to_s.yellow}." ) do |v|
      raise BetterCap::Error, "Invalid port '#{v}' specified." unless Network::Validator.is_valid_port?(v)
      @dnsd_port = v.to_i
    end

  end

end

end
