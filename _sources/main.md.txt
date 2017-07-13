General Options
============

The following are the main options that determine the general behaviour of BetterCap, **these options are not mandatory**, in fact bettercap will automatically detect everything it needs in order to work, you just might need to use one or more of the following options to specify some custom behaviour in specific cases.

## Examples

Attack specific targets:

`sudo bettercap -T 192.168.1.10,192.168.1.11`

Attack a specific target by its MAC address:

`sudo bettercap -T 01:23:45:67:89:10`

Attack a range of IP addresses:

`sudo bettercap -T 192.168.1.1-30`

Attack a specific subnet:

`sudo bettercap -T 192.168.1.1/24`

Randomize the interface MAC address during the attack:

`sudo bettercap --random-mac`

## Options

### `-I, --interface IFACE`

BetterCAP will automatically detect your default network interface and use it, if you want to make it use another interface ( when you have more than one, let's say `eth0` and `wlan0` ) you can use this option.

### `--use-mac ADDRESS`

Change the interface MAC address to this value before performing the attack.

### `--random-mac`

Change the interface MAC address to a random one before performing the attack.

### `-G, --gateway ADDRESS`

The same goes for the gateway, either let bettercap automatically detect it or manually specify its address.

### `-T, --target ADDRESS1,ADDRESS2`

If no specific target is given on the command line, bettercap will spoof every single address on the network. There are cases when you already know the IP or MAC address of your target(s), in such cases you can use this option.

### `--ignore ADDRESS1,ADDRESS2`

Ignore these IP addresses if found while searching for targets.

### `--no-discovery`

Do not actively search for hosts, just use the current ARP cache, default to `false`.

### `--no-target-nbns`

Disable target NBNS hostname resolution.

### `--packet-throttle NUMBER`

Number of seconds ( can be a decimal number ) to wait between each packet to be sent.

### `--check-updates`

Will check if any update is available and then exit.

### `-h, --help`

Display the available options.
