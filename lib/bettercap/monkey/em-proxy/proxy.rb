class Proxy

  def self.start(options, &blk)
    # epoll is not supported on OSX!
    # EM.epoll
    EM.run do
      # We'll take care of this.
      #
      # trap("TERM") { stop }
      # trap("INT")  { stop }

      EventMachine::start_server(options[:host], options[:port],
                                 EventMachine::ProxyServer::Connection, options) do |c|
        c.instance_eval(&blk)
      end
    end
  end

  def self.stop
    EventMachine.stop
  rescue
  end
end
