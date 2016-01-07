This is a list of TODOs I use to keep track of tasks and upcoming features.

---

- [x] Implement `--ignore ADDR,ADDR,ADDR` option to filter out specific addresses from the targets list.
- [x] HTTP 1.1 chunked response support.
- [x] Ip address to hostname resolution.
- [x] Wrap every class with `module BetterCap` and refactor old code.
- [x] Use StreamLogger for both Proxy and Sniffer traffic.
- [x] Implement `--custom-parser REGEX` option.
- [x] Let `-T|--target` [support MAC addresses](https://github.com/evilsocket/bettercap/issues/82).
- [x] Fix modules structure by folder.
- [x] Document classes with RDoc.
- [ ] Rewrite proxy class using [em-proxy](https://github.com/igrigorik/em-proxy) library.
- [ ] HTTP/2 Support.

**Platform Specific**

- [ ] *BSD Support.
- [ ] Windows Support? ( OMG PLZ NO! )
- [ ] GNU/Linux [Active packet filtering/injection/etc](https://github.com/evilsocket/bettercap/issues/75) ( maybe using [this](https://github.com/gdelugre/ruby-nfqueue) ).

**Maybe**

- [ ] Implement event-driven core plugin infrastructure ( for webui, etc ).
- [ ] Implement web-ui core plugin.
- [ ] ICMP Redirect ? ( only half duplex and filtered by many firewalls anyway ... dunno ).
- [ ] DNS Spoofing ( not sure if it actually makes any sense ).
- [ ] sslstrip ( not really sure, currently is quite useless )
- [ ] Implement `--mkcert FILENAME` option to create custom HTTPS `crt` files.
- [ ] IPV6 Support.
