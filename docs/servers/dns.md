DNS
============

If you want to perform DNS [spoofing](/docs/spoofing.html), you must specify the `--dns FILE` command line argument, where the `FILE` value is the name of a file composed by entries like the following:

<script src="https://gist.github.com/evilsocket/2bea18a6db6af7deeb6c.js"></script>

Then all you've left to do is execute:

    sudo bettercap --dns dns.conf

<hr/>

#### `--dns FILE`

Enable DNS server and use this file as a hosts resolution table.

#### `--dns-port PORT`

Set DNS server port, default to `5300`.
