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
    http.ssl_timeout =
    http.open_timeout =
    http.read_timeout = 10

    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    http.head("/")
    http.certificate
  end
end

# Used as an on-disk cache of server certificates.
class Store
  # The store path.
  PATH = File.join( Dir.home, '.bettercap', 'certificates' )

  # Create an instance of this class.
  def initialize
    unless File.directory?( Store::PATH )
      Logger.info "[#{'SSL'.green}] Initializing certificates store '#{Store::PATH}' ..."
      FileUtils.mkdir_p( Store::PATH )
    end

    @store = {}
    @lock  = Mutex.new
  end

  # Find the +hostname+:+port+ certificate and return it.
  def find( hostname, port )
    key = Digest::SHA256.hexdigest( "#{hostname}_#{port}" )

    @lock.synchronize {
      unless @store.has_key?(key)
        # Certificate not available in memory, search it in the store PATH.
        filename = File.join( Store::PATH, key )
        s_cert = load_from_file( filename )
        # Not available on disk too, fetch it from the server and save it.
        if s_cert.nil?
          Logger.info "[#{'SSL'.green}] Fetching certificate from #{hostname}:#{port} ..."

          s_cert = Fetcher.fetch( hostname, port )
          save_to_file( s_cert, filename )
        else
          Logger.debug "[#{'SSL'.green}] Loaded HTTPS certificate for '#{hostname}' from store."
        end

        @store[key] = s_cert
      end
    }

    @store[key]
  end

  private

  # Load and return a certificate from +filename+ if it exists, also check if
  # the certificate is expired, in which case it will remove it and return nil.
  def load_from_file( filename )
    cert = nil
    if File.exist?(filename)
      data = File.read(filename)
      cert = OpenSSL::X509::Certificate.new(data)
      # Check if expired.
      now = Time.now
      if now < cert.not_before or now > cert.not_after
        File.delete( filename )
        cert = nil
      end
    end
    cert
  end

  # Save the +cert+ certificate to +filename+ encoded as PEM.
  def save_to_file( cert, filename )
    File.open( filename, "w+" ) { |file| file.write(cert.to_pem) }
  end
end

# This class represents bettercap's HTTPS CA.
class Authority
  # Default CA file.
  DEFAULT = File.join( Dir.home, '.bettercap', 'bettercap-ca.pem' )

  # CA certificate.
  attr_reader :certificate
  # CA key.
  attr_reader :key

  # Create an instance of this class loading the certificate and key from
  # +filename+ which is expected to be a PEM formatted file.
  # If +filename+ is nil, Authority::DEFAULT will be used instead.
  def initialize( filename = nil )
    install_ca
    filename ||= Authority::DEFAULT

    Logger.info "[#{'SSL'.green}] Loading HTTPS Certification Authority from '#{filename}' ..."

    begin
      pem = File.read(filename)

      @certificate = OpenSSL::X509::Certificate.new(pem)
      @key         = OpenSSL::PKey::RSA.new(pem)
      @store       = Store.new
      @cache       = {}
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
  def spoof( hostname, port = 443 )
    @lock.synchronize {
      unless @cache.has_key?(hostname)
        # 1. fetch real server certificate
        s_cert = @store.find( hostname, port )
        # 2. Sign it with our CA.
        s_cert.public_key = @key.public_key
        s_cert.issuer     = @certificate.subject
        s_cert.sign( @key, OpenSSL::Digest::SHA256.new )
        # 3. Profit ^_^
        @cache[hostname] = s_cert
      end
    }
    @cache[hostname]
  end

  def install_ca
    unless File.exist?( Authority::DEFAULT )
      root   = File.join( Dir.home, '.bettercap' )
      source = File.dirname(__FILE__) + '/bettercap-ca.pem'

      Logger.info "[#{'SSL'.green}] Installing CA to #{root} ..."

      FileUtils.mkdir_p( root )
      FileUtils.cp( source, root )
    end
  end
end

end
end
end
end
