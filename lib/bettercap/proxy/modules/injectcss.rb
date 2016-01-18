=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
class Injectcss < BetterCap::Proxy::Module
  @@cssdata = nil
  @@cssurl  = nil

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

  def initialize
    raise BetterCap::Error, "No --css-file, --css-url or --css-data options specified for the proxy module." if @@cssdata.nil? and @@cssurl.nil?
  end

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
