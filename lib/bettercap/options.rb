require 'optparse'
require 'bettercap'
require 'forwardable'

module BetterCap
  class Options
    attr_accessor :options
    attr_reader :ctx

    extend Forwardable

    def_delegators :@options, :[], :[]=

    def initialize(argv)
      @ctx = Context.get
      @options = {}
      parse(argv)
    end

    private

    def parse(argv)
      OptionParser.new do |opts|
        opts.banner = "Usage: #{$0} [options]"
        opts.version = VERSION

        opts.on( '-I', '--interface IFACE', 'Network interface name - default: ' + ctx.options[:iface].to_s ) do |v|
          options[:iface] = v
        end

        opts.on( '-S', '--spoofer NAME', 'Spoofer module to use, available: ' + SpooferFactory.available.join(', ') + ' - default: ' + ctx.options[:spoofer] ) do |v|
          options[:spoofer] = v
        end

        opts.on( '-T', '--target ADDRESS1,ADDRESS2', 'Target IP addresses, if not specified the whole subnet will be targeted.' ) do |v|
          options[:target] = v
        end

        opts.on( '-O', '--log LOG_FILE', 'Log all messages into a file, if not specified the log messages will be only print into the shell.' ) do |v|
          options[:logfile] = v
        end

        opts.on( '-D', '--debug', 'Enable debug logging.' ) do
          options[:debug] = true
        end

        opts.on( '-L', '--local', 'Parse packets coming from/to the address of this computer ( NOTE: Will set -X to true ), default to false.' ) do
          options[:local] = true
          options[:sniffer] = true
        end

        opts.on( '-X', '--sniffer', 'Enable sniffer.' ) do
          options[:sniffer] = true
        end

        opts.on( '--sniffer-pcap FILE', 'Save all packets to the specified PCAP file ( will enable sniffer ).' ) do |v|
          options[:sniffer] = true
          options[:sniffer_pcap] = File.expand_path v
        end

        opts.on( '--sniffer-filter EXPRESSION', 'Configure the sniffer to use this BPF filter ( will enable sniffer ).' ) do |v|
          options[:sniffer] = true
          options[:sniffer_filter] = v
        end

        opts.on( '-P', '--parsers PARSERS', 'Comma separated list of packet parsers to enable, "*" for all ( NOTE: Will set -X to true ), available: ' + ParserFactory.available.join(', ') + ' - default: *' ) do |v|
          options[:sniffer] = true
          options[:parsers] = ParserFactory.from_cmdline(v)
        end

        opts.on( '--no-discovery', 'Do not actively search for hosts, just use the current ARP cache, default to false.' ) do
          options[:arpcache] = true
        end

        opts.on( '--no-spoofing', 'Disable spoofing, alias for --spoofer NONE.' ) do
          options[:spoofer] = 'NONE'
        end

        opts.on( '--half-duplex', 'Enable half-duplex MITM, this will make bettercap work in those cases when the router is not vulnerable.' ) do
          options[:half_duplex] = true
        end

        opts.on( '--proxy', 'Enable HTTP proxy and redirects all HTTP requests to it, default to false.' ) do
          options[:proxy] = true
        end

        opts.on( '--proxy-https', 'Enable HTTPS proxy and redirects all HTTPS requests to it, default to false.' ) do
          options[:proxy] = true
          options[:proxy_https] = true
        end

        opts.on( '--proxy-port PORT', 'Set HTTP proxy port, default to ' + ctx.options[:proxy_port].to_s + ' .' ) do |v|
          options[:proxy] = true
          options[:proxy_port] = v.to_i
        end

        opts.on( '--proxy-https-port PORT', 'Set HTTPS proxy port, default to ' + ctx.options[:proxy_https_port].to_s + ' .' ) do |v|
          options[:proxy] = true
          options[:proxy_https] = true
          options[:proxy_https_port] = v.to_i
        end

        opts.on( '--proxy-pem FILE', 'Use a custom PEM certificate file for the HTTPS proxy.' ) do |v|
          options[:proxy] = true
          options[:proxy_https] = true
          options[:proxy_pem_file] = File.expand_path v
        end

        opts.on( '--proxy-module MODULE', 'Ruby proxy module to load.' ) do |v|
          options[:proxy] = true
          options[:proxy_module] = File.expand_path v
        end

        opts.on( '--httpd', 'Enable HTTP server, default to false.' ) do
          options[:httpd] = true
        end

        opts.on( '--httpd-port PORT', 'Set HTTP server port, default to ' + ctx.options[:httpd_port].to_s +  '.' ) do |v|
          options[:httpd] = true
          options[:httpd_port] = v.to_i
        end

        opts.on( '--httpd-path PATH', 'Set HTTP server path, default to ' + ctx.options[:httpd_path] +  '.' ) do |v|
          options[:httpd] = true
          options[:httpd_path] = v
        end

        opts.on( '--check-updates', 'Will check if any update is available and then exit.' ) do
          options[:check_updates] = true
        end

        opts.on('-h', '--help', 'Display the available options.') do
          puts opts
          puts "\nExamples:\n".bold
          puts " - Sniffer / Credentials Harvester\n".bold
          puts "  Default sniffer mode, all parsers enabled:\n\n"
          puts "    sudo bettercap -X\n".bold
          puts "  Enable sniffer and load only specified parsers:\n\n"
          puts "    sudo bettercap -X -P \"FTP,HTTPAUTH,MAIL,NTLMSS\"\n".bold
          puts "  Enable sniffer + all parsers and parse local traffic as well:\n\n"
          puts "    sudo bettercap -X -L\n".bold
          puts " - Transparent Proxy\n".bold
          puts "  Enable proxy on default ( 8080 ) port with no modules ( quite useless ):\n\n"
          puts "    sudo bettercap --proxy\n".bold
          puts "  Enable proxy and use a custom port:\n\n"
          puts "    sudo bettercap --proxy --proxy-port=8081\n".bold
          puts "  Enable proxy and load the module example_proxy_module.rb:\n\n"
          puts "    sudo bettercap --proxy --proxy-module=example_proxy_module.rb\n".bold
          puts "  Disable spoofer and enable proxy ( stand alone proxy mode ):\n\n"
          puts "    sudo bettercap -S NONE --proxy".bold
          exit
        end

        begin
          argv = ['-h'] if argv.empty?
          opts.parse!(argv)
        rescue OptionParser::ParseError => e
          Logger.error e.message, "\n", opts
          exit -1
        end
      end.parse!

      ctx.options.merge(options)
    end
  end
end
