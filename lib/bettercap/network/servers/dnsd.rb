# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

module BetterCap
module Network
module Servers

# Class to wrap RubyDNS::RuleBasedServer and add some utility methods.
class DnsWrapper < RubyDNS::RuleBasedServer
  # List of redirection rules.
  attr_accessor :rules
  # we need this in order to add rules at runtime.
  @@instance = nil

  # Return the active instance of this object.
  def self.get
    @@instance
  end

  # Instantiate a server with a block.
  def initialize(options = {}, &block)
    super(options,&block)
    @rules     = []
    @@instance = self
  end
  # Give a name and a record type, try to match a rule and use it for processing the given arguments.
  def process(name, resource_class, transaction)
    Logger.debug "[#{'DNS'.green}] Received #{resource_class.name} request for #{name} ..."
    super
  end
end

# Simple DNS server class used for DNS spoofing.
class DNSD
  # Initialize the DNS server with the specified +address+ and tcp/udp +port+.
  # The server will load +hosts_filename+ composed by 'regexp -> ip' entries
  # to do custom DNS spoofing/resolution.
  def initialize( hosts_filename = nil, address = '0.0.0.0', port = 5300 )
    @port    = port
    @address = address
    @hosts   = hosts_filename
    @server  = nil
    @ifaces  = [
      [:udp, address, port],
      [:tcp, address, port]
    ]
  end

  # Add a rule to the DNS resolver at runtime.
  def add_rule!( exp, addr )
    Logger.debug "[#{'DNS'.green}] Adding rule: '#{exp}' -> '#{addr}' ..."

    block = Proc.new do |transaction|
      Logger.info "[#{transaction.options[:peer]} > #{'DNS'.green}] Received request for '#{transaction.question.to_s.yellow}', sending spoofed reply #{addr.yellow} ..."
      begin
        transaction.respond!(addr)
      rescue Exception => e
        Logger.warn "[#{'DNS'.green}] #{e.message}"
        Logger.exception e
      end
    end

    DnsWrapper.get.rules << RubyDNS::RuleBasedServer::Rule.new( [ Regexp.new(exp), Resolv::DNS::Resource::IN::A ], block )
  end

  # Start the server.
  def start
    Logger.info "[#{'DNS'.green}] Starting on #{@address}:#{@port} ..."

    options = {
      :listen => @ifaces,
      :asynchronous => true,
      :server_class => DnsWrapper
    }

    begin
      RubyDNS::run_server( options ) do
        # Suppress RubyDNS logging.
        @logger.level = ::Logger::ERROR
        @upstream ||= RubyDNS::Resolver.new([[:udp, "8.8.8.8", 53], [:tcp, "8.8.8.8", 53]])

        # Default DNS handler
        otherwise do |transaction|
          Logger.debug "[#{transaction.options[:peer]} > #{'DNS'.green}] Received request for '#{transaction.question.to_s.yellow}' -> upstream DNS"
          transaction.passthrough!(@upstream)
        end
      end

      unless @hosts.nil?
        DNSD.parse_hosts( @hosts ).each do |exp,addr|
          add_rule!( exp, addr )
        end
      end
    rescue Errno::EADDRINUSE
      raise BetterCap::Error, "[DNS] It looks like there's another process listening on #{@address}:#{@port}, please chose a different port."
    end
  end

  # Stop the server.
  def stop; end

  # Parse hosts from +filename+, example host file:
  #
  # # *.google.com will point to the attacker's computer.
  # local .*google\.com
  #
  # # a custom redirection
  # 12.12.12.12 wtf.idontexist.com
  def self.parse_hosts( filename )
    raise BetterCap::Error, "File '#{filename}' does not exist." unless File.exist?(filename)

    hosts = {}
    File.open(filename).each_with_index do |line,lineno|
      line = line.strip
      # skip empty lines and comments
      next if line.empty? or line[0] == '#'
      if line =~ /^([^\s]+)\s+(.+)$/
        address    = $1
        expression = $2

        if address == 'local'
          address = Context.get.iface.ip.to_s
        end

        raise BetterCap::Error, "Invalid IPv4 address '#{address}' on line #{lineno + 1} of '#{filename}'." \
          unless Network::Validator.is_ip?(address)

        begin
          hosts[ expression ] = address
        rescue RegexpError
          raise BetterCap::Error, "Invalid expression '#{expression}' on line #{lineno + 1} of '#{filename}'."
        end
      end
    end

    hosts
  end
end

end
end
end
