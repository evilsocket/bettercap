# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

# Add accept_nonblock method to OpenSSL::SSL::SSLServer
module OpenSSL
  module SSL
    class SSLServer
      unless public_method_defined? :accept_nonblock
        def accept_nonblock
          sock = @svr.accept_nonblock

          begin
            ssl = OpenSSL::SSL::SSLSocket.new(sock, @ctx)
            ssl.sync_close = true
            ssl.accept if @start_immediately
            ssl
          rescue SSLError => ex
            sock.close
            raise ex
          end
        end
      end
    end
  end
end
