# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

# This proxy module will take care of CSS code injection.
class InjectCSS < BetterCap::Proxy::Module
  # CSS data to be injected.
  @@cssdata = nil
  # CSS file URL to be injected.
  @@cssurl  = nil

  # Add custom command line arguments to the +opts+ OptionParser instance.
  def self.on_options(opts)
    opts.separator ""
    opts.separator "Inject CSS Proxy Module Options:"
    opts.separator ""

    opts.on( '--css-data STRING', 'CSS code to be injected.' ) do |v|
      @@cssdata = v
      unless @@cssdata.include?("<style>")
        @@cssdata = "<style>\n#{@@cssdata}\n</style>"
      end
    end

    opts.on( '--css-file PATH', 'Path of the CSS file to be injected.' ) do |v|
      filename = File.expand_path v
      raise BetterCap::Error, "#{filename} invalid file." unless File.exists?(filename)
      @@cssdata = File.read( filename )
      unless @@cssdata.include?("<style>")
        @@cssdata = "<style>\n#{@@cssdata}\n</style>"
      end
    end

    opts.on( '--css-url URL', 'URL the CSS file to be injected.' ) do |v|
      @@cssurl = v
    end
  end

  # Create an instance of this module and raise a BetterCap::Error if command
  # line arguments weren't correctly specified.
  def initialize
    raise BetterCap::Error, "No --css-file, --css-url or --css-data options specified for the proxy module." if @@cssdata.nil? and @@cssurl.nil?
  end

  # Called by the BetterCap::Proxy::Proxy processor on each HTTP +request+ and
  # +response+.
  def on_request( request, response )
    # is it a html page?
    if response.content_type =~ /^text\/html.*/
      BetterCap::Logger.info "Injecting CSS #{if @@cssdata.nil? then "URL" else "file" end} into http://#{request.host}#{request.url}"
      # inject URL
      if @@cssdata.nil?
        response.body.sub!( '</head>', "  <link rel=\"stylesheet\" href=\"#{@cssurl}\"></script></head>" )
      # inject data
      else
        response.body.sub!( '</head>', "#{@@cssdata}</head>" )
      end
    end
  end
end
