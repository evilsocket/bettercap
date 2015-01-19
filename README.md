BetterCap
==

Copyleft of **Simone 'evilsocket' Margaritelli**.  
http://www.evilsocket.net/

---

BetterCap is an attempt to create a complete, modular, portable and easily extensible **MITM** framework with every kind of features could be needed while performing a man in the middle attack.  

**This software is currently alpha stage, its usage is not recommended unless you really know what you are doing.**

TODO
===

- **FIXES**
  - [x] Whole subnet will take a lot of time due to arp packets needed to get hardware addresses.

- **General**
  - [x] Implement abstraction interfaces.
  - [x] Support multiple targets at once.
  - [ ] Auto host discovery/scanning and auto add.
  - [ ] HTTP modular transparent proxy with plugins.

- **Firewalling**
  - [x] Implement Firewall class for OS X.
  - [x] Implement Firewall class for GNU/Linux.
  - [x] Traffic redirection feature.

- **Spoofers**  
  - [x] ARP spoofer.
  - [ ] ICMP spoofer.
  - [ ] ICMP6 spoofer.


DEPENDS
===
  - colorize (**gem install colorize**)
  - packetfu (**gem install packetfu**)
  - pcaprub  (**gem install pcaprub**) [sudo apt-get install ruby-dev libpcap-dev]
