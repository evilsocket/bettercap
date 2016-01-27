# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require 'bettercap/version'
require 'bettercap/error'
require 'bettercap/logger'
require 'net/http'
require 'json'

module BetterCap
# This class is responsible for fetching the latest version of
# bettercap and check if a new one is available.
class UpdateChecker
  # Check if a new version is available, printing the results
  # in human readable form.
  def self.check
    ver = self.get_latest_version
    if self.vton( BetterCap::VERSION ) < self.vton( ver )
      Logger.warn "New version '#{ver}' available!"
    else
      Logger.info 'You are running the latest version.'
    end
  rescue Exception => e
    Logger.error("Error '#{e.class}' while checking for updates: #{e.message}")
  end

  # Convert a version string +v+ to a number to be used for comparation.
  def self.vton v
    vi = 0.0
    v.split('.').reverse.each_with_index do |e,i|
      vi += ( e.to_i * 10**i ) - ( if e =~ /[\d+]b/ then 0.5 else 0 end )
    end
    vi
  end

  # Fetch the latest program version from rubygems.org API.
  def self.get_latest_version
    Logger.info 'Checking for updates ...'

    api = URI('https://rubygems.org/api/v1/versions/bettercap/latest.json')
    response = Net::HTTP.get_response(api)

    case response
    when Net::HTTPSuccess
      json = JSON.parse(response.body)
    else
      raise response.message
    end

    return json['version']
  end
end
end
