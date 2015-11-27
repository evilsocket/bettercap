This is a list of TODOs I use to keep track of tasks and upcoming features.

---

- [x] Replace PacketFu::Utils::whoami? with something else.
- [x] Capture to .pcap file.
- [x] BPF filters.
- [x] BeEF proxy module ( [BeefBOX](https://github.com/evilsocket/bettercap-proxy-modules/blob/master/beefbox.rb) ).
- [x] Use raw file arp parsing instead of "arp -a" to improve speed. ( Solved with arp -a -n )
- [x] sslmitm
- [ ] Implement --custom-proxy option to redirect traffic to [3rd party tools such as Burp](https://twitter.com/c3c/status/670335125662601216).
- [ ] *BSD Support.
- [ ] HTTP/2 Support.
- [ ] [Active packet filtering/injection/etc](https://github.com/evilsocket/bettercap/issues/75) ( maybe using [this](https://github.com/gdelugre/ruby-nfqueue) ).

**Maybe**

- [ ] Replace webrick with thin ( proxy too? )
- [ ] ICMP Redirect ? ( only half duplex and filtered by many firewalls anyway ... dunno ).
- [ ] DNS Spoofing ( not sure if it actually makes any sense ).
- [ ] Windows Support? ( OMG PLZ NO! )
- [ ] Output/actions as json for UI integration?
- [ ] sslstrip ( not really sure, currently is quite useless )
