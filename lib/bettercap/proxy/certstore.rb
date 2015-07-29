=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require 'bettercap/logger'
require 'openssl'

module Proxy
  class CertStore
    @@selfsigned = {}
    @@frompems = {}

    def self.from_file( filename )
      if !@@frompems.has_key? filename
        Logger.info "Loading self signed HTTPS certificate from '#{filename}' ..."

        pem = File.read filename

        @@frompems[filename] = { :cert => OpenSSL::X509::Certificate.new(pem), :key => OpenSSL::PKey::RSA.new(pem) }
      end

      @@frompems[filename]
    end

    # TODO: Put a better default subject here!
    def self.get_selfsigned( subject = '/C=BE/O=Test/OU=Test/CN=Test' )
      if !@@selfsigned.has_key? subject
        Logger.info "Generating self signed HTTPS certificate for subject '#{subject}' ..."

        key = OpenSSL::PKey::RSA.new(2048)
        public_key = key.public_key

        cert = OpenSSL::X509::Certificate.new
        cert.subject = cert.issuer = OpenSSL::X509::Name.parse(subject)
        cert.not_before = Time.now
        cert.not_after = Time.now + 365 * 24 * 60 * 60
        cert.public_key = public_key
        cert.serial = 0x0
        cert.version = 2

        ef = OpenSSL::X509::ExtensionFactory.new
        ef.subject_certificate = cert
        ef.issuer_certificate = cert
        cert.extensions = [
            ef.create_extension("basicConstraints","CA:TRUE", true),
            ef.create_extension("subjectKeyIdentifier", "hash"),
            ef.create_extension("keyUsage", "cRLSign,keyCertSign", true),
        ]
        cert.add_extension ef.create_extension("authorityKeyIdentifier",
                                               "keyid:always,issuer:always")

        cert.sign key, OpenSSL::Digest::SHA256.new

        @@selfsigned[subject] = { :cert => cert, :key => key }
      end

      @@selfsigned[subject]
    end
  end

end
