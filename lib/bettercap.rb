#!/usr/bin/env ruby

=begin

  BETTERCAP

  Author : Simone 'evilsocket' Margaritelli
  Email  : evilsocket@gmail.com
  Blog   : http://www.evilsocket.net/

  This project is released under the GPL 3 license.

=end

require 'optparse'
require 'colorize'
require 'packetfu'
require 'ipaddr'

Object.send :remove_const, :Config rescue nil
Config = RbConfig

require 'bettercap/error'
require 'bettercap/context'
require 'bettercap/monkey/packetfu/utils'
require 'bettercap/factories/firewall_factory'
require 'bettercap/factories/spoofer_factory'
require 'bettercap/factories/parser_factory'
require 'bettercap/logger'
require 'bettercap/shell'
require 'bettercap/network'
require 'bettercap/version'
require 'bettercap/target'
require 'bettercap/sniffer/sniffer'
require 'bettercap/proxy/request'
require 'bettercap/proxy/response'
require 'bettercap/proxy/proxy'
require 'bettercap/proxy/module'
require 'bettercap/proxy/certstore'
require 'bettercap/httpd/server'
