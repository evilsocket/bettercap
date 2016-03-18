TCP
============

If you want to actively modify packets of a TCP protocol which is not HTTP or HTTPS, you'll need the TCP proxy. This event-based proxy will allow you to intercept anything sent/received to/from a specific host using your own custom module.

## Sample Module

The following example module won't do anything but dumping the data being transmitted from/to the target, you can access the [event](http://www.rubydoc.info/gems/bettercap/1.5.0/BetterCap/Proxy/TCP/Event) object in order to modify the data on the fly.

<script src="https://gist.github.com/evilsocket/36da77e34766dc600218.js"></script>

If you want to load such module and dump all the ( let's say ) MySQL traffic from/to the `mysql.example.com` host you would do:

    sudo bettercap --tcp-proxy-module example.rb --tcp-proxy-upstream mysql.example.com:3306

And you would be ready to go.

<hr/>

## Options

### `--tcp-proxy`

Enable the TCP proxy ( requires other `--tcp-proxy-*` options to be specified ).

### `--tcp-proxy-module MODULE`

Ruby TCP proxy module to load.

### `--tcp-proxy-port PORT`

Set local TCP proxy port, default to `2222`.

### `--tcp-proxy-upstream-address ADDRESS`

Set TCP proxy upstream server address.

### `--tcp-proxy-upstream-port PORT`

Set TCP proxy upstream server port.

### `--tcp-proxy-upstream ADDRESS:PORT`

Set TCP proxy upstream server address and port ( shortcut for `--tcp-proxy-upstream-address ADDRESS` and `--tcp-proxy-upstream-port PORT` ).
