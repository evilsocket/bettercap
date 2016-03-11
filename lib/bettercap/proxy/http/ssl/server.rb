# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

module BetterCap
module Proxy
module HTTP
module SSL

# Little utility class to handle SSLServer creation.
class Server
  # The SSL certification authority.
  attr_reader :authority
  # Main SSLContext instance.
  attr_reader :context
  # Socket I/O object.
  attr_reader :io

  # Create an instance from the TCPSocket +socket+.
  def initialize( socket )
    @authority    = Authority.new( Context.get.options.proxies.proxy_pem_file )
    @context      = OpenSSL::SSL::SSLContext.new
    @context.cert = @authority.certificate
    @context.key  = @authority.key

    # If the client supports SNI ( https://en.wikipedia.org/wiki/Server_Name_Indication )
    # we'll receive the hostname it wants to connect to in this callback.
    # Use the CA we already have loaded ( or generated ) to sign a new
    # certificate at runtime with the correct 'Common Name' and create a new SSL
    # context with it, these are the steps:
    #
    # 1. Get hostname from SNI.
    # 2. Fetch upstream certificate from the real server.
    # 3. Resign it with our own CA.
    # 4. Create a new context with the new spoofed certificate.
    # 5. Profit ^_^
    @context.servername_cb = proc { |sslsocket, hostname|
      Logger.debug "[#{'SSL'.green}] Server-Name-Indication for '#{hostname}'"

      ctx      = OpenSSL::SSL::SSLContext.new
      ctx.cert = @authority.spoof( hostname )
      ctx.key  = @authority.key

      ctx
    }

    @io = OpenSSL::SSL::SSLServer.new( socket, @context )
  end
end

end
end
end
end
