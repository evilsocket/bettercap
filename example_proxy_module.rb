=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
class HackTitle < Proxy::Module
  def on_request( request, response )
    # is it a html page?
    if response.content_type == 'text/html'
      Logger.info "Hacking http://#{request.host}#{request.url} title tag"
      # make sure to use sub! or gsub! to update the instance
      response.body.sub!( '<title>', '<title> !!! HACKED !!! ' )
    end
  end
end
