#!/usr/bin/env ruby
# encoding: UTF-8

=begin

  BETTERCAP

  Author : Simone 'evilsocket' Margaritelli
  Email  : evilsocket@gmail.com
  Blog   : https://www.evilsocket.net/

  This project is released under the GPL 3 license.

=end

# they hate us 'cause they ain't us
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

require 'packetfu'
require 'em-proxy'
require 'webrick'
require 'rubydns'
require 'colorize'
require 'json'
require 'net/dns'
require 'net/http'
require 'optparse'
require 'io/console'

Object.send :remove_const, :Config rescue nil
Config = RbConfig

def bettercap_autoload(path = '')
  dir    = File.dirname(__FILE__) + "/bettercap/#{path}"
  deps   = []
  files  = []
  monkey = []

  Dir[dir + '**/*.rb'].each do |filename|
    filename = filename.gsub(dir, '').gsub('.rb', '')
    filename = "bettercap/#{path}#{filename}"

    next if filename.include?('proxy/http/modules')
    # Proxy modules must be loaded at runtime.
    if filename.end_with?('/base') || filename.include?('pluggable')
      deps << filename
    elsif filename.include?('monkey')
      monkey << filename
    else
      files << filename
    end
  end

  (deps + files + monkey).each do |file|
    require file
  end
end

bettercap_autoload
