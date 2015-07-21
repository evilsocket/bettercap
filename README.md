BetterCap
==

Copyleft of **Simone 'evilsocket' Margaritelli**.  
http://www.evilsocket.net/

---

BetterCap is an attempt to create a complete, modular, portable and easily extensible **MITM** framework with every kind of features could be needed while performing a man in the middle attack.  

It's currently able to sniff and print from the network the following informations:

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

DEPENDS
===
- colorize (**gem install colorize**)
- packetfu (**gem install packetfu**)
- pcaprub  (**gem install pcaprub**) [sudo apt-get install ruby-dev libpcap-dev]
