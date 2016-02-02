#!/usr/bin/env ruby
# encoding: UTF-8

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
require 'uri'

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
require 'bettercap/spoofers/base'
require 'bettercap/spoofers/arp'
require 'bettercap/spoofers/icmp'
require 'bettercap/spoofers/none'
require 'bettercap/logger'
require 'bettercap/shell'
require 'bettercap/network/network'
require 'bettercap/version'
require 'bettercap/network/target'
require 'bettercap/sniffer/sniffer'
require "bettercap/sniffer/parsers/base"
require "bettercap/sniffer/parsers/custom"
require "bettercap/sniffer/parsers/dict"
require "bettercap/sniffer/parsers/cookie"
require "bettercap/sniffer/parsers/ftp"
require "bettercap/sniffer/parsers/httpauth"
require "bettercap/sniffer/parsers/https"
require "bettercap/sniffer/parsers/irc"
require "bettercap/sniffer/parsers/mail"
require "bettercap/sniffer/parsers/mpd"
require "bettercap/sniffer/parsers/nntp"
require "bettercap/sniffer/parsers/ntlmss"
require "bettercap/sniffer/parsers/post"
require "bettercap/sniffer/parsers/redis"
require "bettercap/sniffer/parsers/rlogin"
require "bettercap/sniffer/parsers/snpp"
require "bettercap/sniffer/parsers/url"
require 'bettercap/firewalls/redirection'
require 'bettercap/firewalls/osx'
require 'bettercap/firewalls/linux'
require 'bettercap/proxy/stream_logger'
require 'bettercap/proxy/request'
require 'bettercap/proxy/response'
require 'bettercap/proxy/thread_pool'
require 'bettercap/proxy/sslstrip/cookiemonitor'
require 'bettercap/proxy/sslstrip/urlmonitor'
require 'bettercap/proxy/sslstrip/strip'
require 'bettercap/proxy/proxy'
require 'bettercap/proxy/streamer'
require 'bettercap/proxy/module'
require 'bettercap/proxy/certstore'
require 'bettercap/network/servers/httpd'
require 'bettercap/network/servers/dnsd'
