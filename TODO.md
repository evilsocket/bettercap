This is a list of TODOs I use to keep track of tasks and upcoming features.

---

- [x] Implement `--ignore ADDR,ADDR,ADDR` option to filter out specific addresses from the targets list.
- [ ] Implement event-driven core plugin infrastructure ( for webui, etc ).
- [ ] Implement web-ui core plugin.
- [ ] Rewrite proxy class using [em-proxy](https://github.com/igrigorik/em-proxy) library.
- [ ] [Active packet filtering/injection/etc](https://github.com/evilsocket/bettercap/issues/75) ( maybe using [this](https://github.com/gdelugre/ruby-nfqueue) ).
- [ ] *BSD Support.
- [ ] HTTP/2 Support.

**Maybe**

- [ ] ICMP Redirect ? ( only half duplex and filtered by many firewalls anyway ... dunno ).
- [ ] DNS Spoofing ( not sure if it actually makes any sense ).
- [ ] Windows Support? ( OMG PLZ NO! )
- [ ] Output/actions as json for UI integration?
- [ ] sslstrip ( not really sure, currently is quite useless )
