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

class UpdateChecker
  def self.check
    ver = self.get_latest_version
    case ver
    when BetterCap::VERSION
      Logger.info 'You are running the latest version.'
    else
      Logger.warn "New version '#{ver}' available!"
    end
  rescue Exception => e
    Logger.error("Error '#{e.class}' while checking for updates: #{e.message}")
  end

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
