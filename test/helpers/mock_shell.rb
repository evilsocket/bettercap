module MockShell
  class << self
    # For easy testing, this method just returns back the command it is given.
    # The real Shell class will return the output string.
    def execute(command)
      return command
    end

    def ifconfig(iface = '')
      self.execute("LANG=en && inconfig #{iface}")
    end

    def arp
      self.execute('LANG=en && arp -a')
    end
  end
end
