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

| Screenshots |
|:-----:|
| ![Screen1](https://raw.githubusercontent.com/evilsocket/bettercap/master/screenshot.png) |

PROXY
===

A modular transparent proxy can be started with the --proxy argument, by default it won't do anything 
but logging HTTP requests, but if you specify a **--proxy-module** argument you will be able to load
your own modules and manipulate HTTP traffic as you like.  

You can easily implement a module to inject data into pages or just inspect the
requests/responses creating a ruby file and passing it to bettercap with the --proxy-module argument, 
the following is a sample module that injects some contents into the title tag of each html page.

```ruby
class HackTitle < Proxy::Module
    def initialize
        # do your initialization stuff here
    end

    # self explainatory
    def is_enabled?
        return true
    end

    def on_request request, response
        # is an html page?
        if response.content_type == "text/html"
            Logger.info "Hacking #{http://#{request.host}#{request.url}} title tag"

            # make sure to use sub! or gsub! to update the instance
            response.body.sub!( "<title>", "<title> !!! HACKED !!! " )
        end
    end
end
```

DEPENDS
===
- colorize (**gem install colorize**)
- packetfu (**gem install packetfu**)
- pcaprub  (**gem install pcaprub**) [sudo apt-get install ruby-dev libpcap-dev]
