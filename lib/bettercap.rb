#!/usr/bin/env ruby

=begin

  BETTERCAP

  Author : Simone 'evilsocket' Margaritelli
  Email  : evilsocket@gmail.com
  Blog   : http://www.evilsocket.net/

  This project is released under the GPL 3 license.

=end

# they hate us 'cause they ain't us
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

require 'optparse'
require 'colorize'
require 'packetfu'
require 'ipaddr'

Object.send :remove_const, :Config rescue nil
Config = RbConfig

require 'bettercap/update_checker'
require 'bettercap/error'
require 'bettercap/loader'
require 'bettercap/options'
require 'bettercap/network/arp_reader'
require 'bettercap/network/packet_queue'
require 'bettercap/discovery/thread'
require 'bettercap/discovery/agents/base'
require 'bettercap/discovery/agents/arp'
require 'bettercap/discovery/agents/icmp'
require 'bettercap/discovery/agents/udp'
require 'bettercap/context'
require 'bettercap/monkey/packetfu/utils'
require 'bettercap/factories/firewall'
require 'bettercap/factories/spoofer'
require 'bettercap/factories/parser'
require 'bettercap/logger'
require 'bettercap/shell'
require 'bettercap/network/network'
require 'bettercap/version'
require 'bettercap/network/target'
require 'bettercap/sniffer/sniffer'
require 'bettercap/firewalls/redirection'
require 'bettercap/proxy/stream_logger'
require 'bettercap/proxy/request'
require 'bettercap/proxy/response'
require 'bettercap/proxy/thread_pool'
require 'bettercap/proxy/sslstrip/urlmonitor'
require 'bettercap/proxy/sslstrip/strip'
require 'bettercap/proxy/proxy'
require 'bettercap/proxy/streamer'
require 'bettercap/proxy/module'
require 'bettercap/proxy/certstore'
require 'bettercap/httpd/server'
