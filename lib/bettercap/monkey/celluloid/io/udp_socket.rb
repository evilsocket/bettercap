# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

# Monkey patching fix for https://github.com/evilsocket/bettercap/issues/154
module Celluloid
  module IO
    class UDPSocket
      def initialize(address_family = ::Socket::AF_INET)
        @socket = ::UDPSocket.new(address_family)
      rescue Errno::EMFILE
        sleep 0.5
        retry
      end
    end
  end
end
