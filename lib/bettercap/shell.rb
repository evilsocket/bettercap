# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : https://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

module BetterCap
# Class responsible of executing various shell commands.
module Shell
  class << self
    # Execute +command+ and return its output.
    # Raise +BetterCap::Error+ if the return code is not 0.
    def execute(command)
      Logger.debug command
      r = ''
      10.times do
        begin
          r=%x(#{command})
          if $? != 0
            raise BetterCap::Error, "Error, executing #{command}"
          end
          break
        rescue Errno::EMFILE => e
          Logger.debug "Retrying command '#{command}' due to Errno::EMFILE error ..."
          sleep 1
        end
      end
      r
    end

    # Cross-platform way of finding an executable in the $PATH.
    def which(cmd)
      exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
      ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
        exts.each { |ext|
          exe = File.join(path, "#{cmd}#{ext}")
          return exe if File.executable?(exe) && !File.directory?(exe)
        }
      end
      return nil
    end

    # Cross-platform way of finding an executable in the $PATH.
    def available?(cmd)
      !which(cmd).nil?
    end

    # Get the +iface+ network interface configuration ( using ifconfig ).
    def ifconfig(iface = '')
      self.execute( "LANG=en && ifconfig #{iface}" )
    end

    # Change the +iface+ mac address to +mac+ using ifconfig.
    def change_mac(iface, mac)
      if RUBY_PLATFORM =~ /.+bsd/ or RUBY_PLATFORM =~ /darwin/
        self.ifconfig( "#{iface} ether #{mac}")
      elsif RUBY_PLATFORM =~ /linux/
        self.ifconfig( "#{iface} hw ether #{mac}")
      else
       raise BetterCap::Error, 'Unsupported operating system'
      end
    end

    # Get the +iface+ network interface configuration ( using iproute2 ).
    def ip(iface = '')
      self.execute( "LANG=en && LANGUAGE=en_EN.UTF-8 && ip addr show #{iface}" )
    end

    # Get the ARP table cached on this computer.
    def arp
      self.execute( 'LANG=en && LANGUAGE=en_EN.UTF-8 && arp -a -n' )
    end

    # Get the NDP table cached on this computer.
    def ndp
      self.execute( 'LANG=en && LANGUAGE=en_EN.UTF-8 && ip -6 neighbor show')
    end

  end
end
end
