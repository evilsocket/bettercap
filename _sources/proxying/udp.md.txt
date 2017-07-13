UDP
============

If you want to actively modify packets of a UDP protocol, you'll need the UDP proxy. This event-based proxy will allow you to intercept anything sent/received to/from a specific host using your own custom module.

## Sample Module

The following example module won't do anything but dumping the data being transmitted from/to the target, you can access the [event](http://www.rubydoc.info/gems/bettercap/1.5.0/BetterCap/Proxy/UDP/Event) object in order to modify the data on the fly.

<script src="https://gist.github.com/evilsocket/7fbbfc9b12826e7de7a1c97a921b7ce8.js"></script>

If you want to load such module and dump all the ( let's say ) DNS traffic from/to the `ns01.example.com` host you would do:

    sudo bettercap --udp-proxy-module example.rb --udp-proxy-upstream ns01.example.com:53

And you would be ready to go.

<hr/>

## Options

### `--udp-proxy`

Enable the UDP proxy ( requires other `--udp-proxy-*` options to be specified ).

### `--udp-proxy-module MODULE`

Ruby UDP proxy module to load.

### `--udp-proxy-port PORT`

Set local UDP proxy port, default to `2222`.

### `--udp-proxy-upstream-address ADDRESS`

Set UDP proxy upstream server address.

### `--udp-proxy-upstream-port PORT`

Set UDP proxy upstream server port.

### `--udp-proxy-upstream ADDRESS:PORT`

Set UDP proxy upstream server address and port ( shortcut for `--udp-proxy-upstream-address ADDRESS` and `--udp-proxy-upstream-port PORT` ).
