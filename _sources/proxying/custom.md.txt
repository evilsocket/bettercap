Third Party Proxies
============

If you want to use some custom proxy of yours ( BurpSuite for instance, or some custom app you wrote ) you can still use bettercap to make the whole process easier, no more crappy shell scripts to apply custom firewall rules and launch "esotic" commands!

For instance, if you want to attack the whole network and redirect all HTTP traffic to your local BurpSuite installation ( in this example `192.168.1.2` is your computer ip address ):

    sudo bettercap --custom-proxy 192.168.1.2

<hr/>

## `--custom-proxy ADDRESS`

Use a custom HTTP upstream proxy instead of the builtin one.

## `--custom-proxy-port PORT`

Specify a port for the custom HTTP upstream proxy, default to `8080`.

## `--custom-https-proxy ADDRESS`

Use a custom HTTPS upstream proxy instead of the builtin one.

## `--custom-https-proxy-port PORT`

Specify a port for the custom HTTPS upstream proxy, default to 8083.

## `--custom-redirection RULE`

Apply a custom port redirection, the format of the rule is `PROTOCOL ORIGINAL_PORT NEW_PORT`.
For instance `TCP 21 2100` will redirect all TCP traffic going to port `21`, to port `2100`.
