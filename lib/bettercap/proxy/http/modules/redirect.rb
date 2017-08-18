# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : https://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

# This proxy module will redirect to a custom URL.
class Redirect < BetterCap::Proxy::HTTP::Module
  meta(
    'Name'        => 'Redirect',
    'Description' => 'This proxy module will redirect the target(s) to a custom URL.',
    'Version'     => '1.0.0',
    'Author'      => "Simone 'evilsocket' Margaritelli",
    'License'     => 'GPL3'
  )

  # URL to redirect the target(s) to.
  @@url = nil
  # Optional regex filter for redirections.
  @@filter = nil

  # Add custom command line arguments to the +opts+ OptionParser instance.
  def self.on_options(opts)
    opts.separator ""
    opts.separator "Redirect Proxy Module Options:"
    opts.separator ""

    opts.on( '--redirect-url URL', 'URL to redirect the target(s) to.' ) do |v|
      @@url = v
    end

    opts.on( '--redirect-filter EXPRESSION', 'Optional regex filter for redirections.' ) do |v|
      @@filter = Regexp.new(v)
    end
  end

  # Create an instance of this module and raise a BetterCap::Error if command
  # line arguments weren't correctly specified.
  def initialize
    raise BetterCap::Error, "No --redirect-url option specified for the proxy module." if @@url.nil?
    raise BetterCap::Error, "Invalid URL specified." unless @@url =~ /\A#{URI::regexp}\z/
  end

  def on_request( request, response )
    if response.content_type =~ /^text\/html.*/ and !@@url.include?(request.host)
      if @@filter.nil? or @@filter.match(request.to_url)
        BetterCap::Logger.info "[#{'REDIRECT'.green}] Redirecting #{request.to_url} to #{@@url} ..."
        response.redirect!(@@url)
      end
    end
  end
end
