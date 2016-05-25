# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

module BetterCap

class CoreOptions
  # Network interface.
  attr_accessor :iface
  # Gateway IP address.
  attr_accessor :gateway
  # Comma separated list of targets.
  attr_accessor :targets
  # Comma separated list of ip addresses to ignore.
  attr_accessor :ignore
  # If false will disable active network discovery, the program will just use
  # the current ARP cache.
  attr_accessor :discovery
  # If true, targets NBNS hostname resolution won't be performed.
  attr_accessor :no_target_nbns
  # Log file name.
  attr_accessor :logfile
  # If true the Logger will prepend timestamps to each line.
  attr_accessor :log_timestamp
  # If true will suppress every log message which is not an error or a warning.
  attr_accessor :silent
  # If true will enable debug messages.
  attr_accessor :debug
  # If different than 0, this time will be used as a delay while sending packets.
  attr_accessor :packet_throttle
  # If true, bettercap will check for updates then exit.
  attr_accessor :check_updates
  # If not nil, the interface MAC address will be changed to this value.
  attr_accessor :use_mac

  def initialize( iface )
    @iface           = iface
    @gateway         = nil
    @targets         = nil
    @logfile         = nil
    @log_timestamp   = false
    @silent          = false
    @debug           = false
    @ignore          = nil
    @discovery       = true
    @no_target_nbns  = false
    @packet_throttle = 0.0
    @check_updates   = false
    @use_mac         = nil
  end

  def parse!( ctx, opts )
    opts.separator ""
    opts.separator "MAIN:".bold
    opts.separator ""

    opts.on( '-I', '--interface IFACE', 'Network interface name - default: ' + @iface.to_s.yellow ) do |v|
      @iface = v
    end

    opts.on( '--use-mac ADDRESS', 'Change the interface MAC address to this value before performing the attack.' ) do |v|
      @use_mac = v
      raise BetterCap::Error, "Invalid MAC address specified." unless Network::Validator.is_mac?(@use_mac)
    end

    opts.on( '--random-mac', 'Change the interface MAC address to a random one before performing the attack.' ) do |v|
      @use_mac = [format('%0.2x', rand(256) & ~1), (1..5).map { format('%0.2x', rand(256)) }].join(':')
    end

    opts.on( '-G', '--gateway ADDRESS', 'Manually specify the gateway address, if not specified the current gateway will be retrieved and used. ' ) do |v|
      @gateway = v
      raise BetterCap::Error, "The specified gateway '#{v}' is not a valid IPv4 address." unless Network::Validator.is_ip?(v)
    end

    opts.on( '-T', '--target ADDRESS1,ADDRESS2', 'Target IP addresses, if not specified the whole subnet will be targeted.' ) do |v|
      self.targets = v
    end

    opts.on( '--ignore ADDRESS1,ADDRESS2', 'Ignore these addresses if found while searching for targets.' ) do |v|
      self.ignore = v
    end

    opts.on( '--no-discovery', "Do not actively search for hosts, just use the current ARP cache, default to #{'false'.yellow}." ) do
      @discovery = false
    end

    opts.on( '--no-target-nbns', 'Disable target NBNS hostname resolution.' ) do
      @no_target_nbns = true
    end

    opts.on( '--packet-throttle NUMBER', 'Number of seconds ( can be a decimal number ) to wait between each packet to be sent.' ) do |v|
      @packet_throttle = v.to_f
      raise BetterCap::Error, "Invalid packet throttle value specified." if @packet_throttle <= 0.0
    end

    opts.on( '--check-updates', 'Will check if any update is available and then exit.' ) do
      @check_updates = true
    end

    opts.on( '-h', '--help', 'Display the available options.') do
      puts opts
      puts "\nFor examples & docs please visit " + "http://bettercap.org/docs/".bold
      exit
    end

    opts.separator ""
    opts.separator "LOGGING:".bold
    opts.separator ""

    opts.on( '-O', '--log LOG_FILE', 'Log all messages into a file, if not specified the log messages will be only print into the shell.' ) do |v|
      @logfile = v
    end

    opts.on( '--log-timestamp', 'Enable logging with timestamps for each line, disabled by default.' ) do
      @log_timestamp = true
    end

    opts.on( '-D', '--debug', 'Enable debug logging.' ) do
      @debug = true
    end

    opts.on( '--silent', "Suppress every message which is not an error or a warning, default to #{'false'.yellow}." ) do
      @silent = true
    end

  end

  def validate!
    raise BetterCap::Error, 'This software must run as root.' unless Process.uid == 0
    raise BetterCap::Error, 'No default interface found, please specify one with the -I argument.' if @iface.nil?
  end

  # Return true if active host discovery is enabled, otherwise false.
  def discovery?
    ( @discovery and @targets.nil? )
  end

  # Split specified targets and parse them ( either as IP or MAC ), will raise a
  # BetterCap::Error if one or more invalid addresses are specified.
  def targets=(value)
    @targets = []

    value.split(",").each do |t|
      if Network::Validator.is_ip?(t) or Network::Validator.is_mac?(t)
        @targets << Network::Target.new(t)

      elsif Network::Validator.is_range?(t)
        Network::Validator.each_in_range( t ) do |address|
          @targets << Network::Target.new(address)
        end

      elsif Network::Validator.is_netmask?(t)
        Network::Validator.each_in_netmask(t) do |address|
          @targets << Network::Target.new(address)
        end

      else
        raise BetterCap::Error, "Invalid target specified '#{t}', valid formats are IP addresses, "\
                                "MAC addresses, IP ranges ( 192.168.1.1-30 ) or netmasks ( 192.168.1.1/24 ) ."
      end
    end
  end

  # Setter for the #ignore attribute, will raise a BetterCap::Error if one
  # or more invalid IP addresses are specified.
  def ignore=(value)
    @ignore = value.split(",")
    valid   = @ignore.select { |target| Network::Validator.is_ip?(target) }

    raise BetterCap::Error, "Invalid ignore addresses specified." if valid.empty?

    invalid = @ignore - valid
    invalid.each do |target|
      Logger.warn "Not a valid address: #{target}"
    end

    @ignore = valid

    Logger.warn "Ignoring #{valid.join(", ")} ."
  end

  # Return true if the +ip+ address needs to be ignored, otherwise false.
  def ignore_ip?(ip)
    !@ignore.nil? and @ignore.include?(ip)
  end
end

end
