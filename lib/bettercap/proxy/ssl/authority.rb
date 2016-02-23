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
module SSL

# Simple wrapper class used to fetch a server HTTPS certificate.
class Fetcher < Net::HTTP
  # The server HTTPS certificate.
  attr_accessor :certificate
  # Overridden from Net::HTTP in order to save the peer certificate
  # before the connection is closed.
  def on_connect
    @certificate = peer_cert
  end
  # Fetch the HTTPS certificate of +hostname+:+port+.
  def self.fetch( hostname, port )
    http             = self.new( hostname, port )
    http.use_ssl     = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    http.head("/")
    http.certificate
  end
end

# This class represents bettercap's HTTPS CA.
class Authority
  # Default CA file.
  DEFAULT = File.dirname(__FILE__) + '/bettercap-ca.pem'
  # CA certificate.
  attr_reader :certificate
  # CA key.
  attr_reader :key

  # Create an instance of this class loading the certificate and key from
  # +filename+ which is expected to be a PEM formatted file.
  # If +filename+ is nil, Authority::DEFAULT will be used instead.
  def initialize( filename = nil )
    filename ||= Authority::DEFAULT

    Logger.info "[#{'SSL'.green}] Loading HTTPS Certification Authority from '#{filename}' ..."

    begin
      pem = File.read(filename)

      @certificate = OpenSSL::X509::Certificate.new(pem)
      @key         = OpenSSL::PKey::RSA.new(pem)
      @store       = {}
      @lock        = Mutex.new
    rescue Errno::ENOENT
      raise BetterCap::Error, "'#{filename}' - No such file or directory."

    rescue OpenSSL::X509::CertificateError
      raise BetterCap::Error, "'#{filename}' - Missing or invalid certificate."

    rescue OpenSSL::PKey::RSAError
      raise BetterCap::Error, "'#{filename}' - Missing or invalid key."
    end
  end

  # Fetch the certificate from +hostname+:+port+, sign it with our own CA and
  # return it.
  def clone( hostname, port = 443 )
    @lock.synchronize {
      unless @store.has_key?(hostname)
        Logger.info "[#{'SSL'.green}] Fetching certificate from #{hostname}:#{port} ..."

        # 1. fetch real server certificate
        s_cert = Fetcher.fetch( hostname, port )

        Logger.debug "[#{'SSL'.green}] #{s_cert.to_pem}"

        # 2. Sign it with our CA.
        s_cert.public_key = @key.public_key
        s_cert.issuer     = @certificate.subject
        s_cert.sign( @key, OpenSSL::Digest::SHA256.new )

        # 3. Profit ^_^
        @store[hostname] = s_cert
      end
    }

    @store[hostname]
  end
end

end
end
end
