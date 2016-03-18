Spoofing
============

As previously described in the introduction section, spoofing is the very hearth of every MITM attack. These options will determine which spoofing technique to use and how to use it.

BetterCap already includes an [ARP spoofer](https://en.wikipedia.org/wiki/ARP_spoofing) ( working both in full duplex and half duplex mode ), a **DNS** spoofer and **the first, fully working and completely automatized [ICMP DoubleDirect spoofer](https://blog.zimperium.com/doubledirect-zimperium-discovers-full-duplex-icmp-redirect-attacks-in-the-wild/) in the world**

## Examples

Use the good old ARP spoofing:

`sudo bettercap` or `sudo bettercap -S ARP` or `sudo bettercap --spoofer ARP`

Use a *full duplex ICMP redirect* spoofing attack:

`sudo bettercap -S ICMP` or `sudo bettercap --spoofer ICMP`

Disable spoofing:

`sudo bettercap -S NONE` or `sudo bettercap --spoofer NONE` or `sudo bettercap --no-spoofing`

No dear 192.168.1.2, you won't connect to anything anymore :D

`sudo bettercap -T 192.168.1.2 --kill`

## Options

### `-S, --spoofer NAME`

Spoofer module to use, available: `ARP`, `ICMP`, `NONE` - default: `ARP`.

### `--no-spoofing`

Disable spoofing, alias for `--spoofer NONE` / `-S NONE`.

### `--kill`

Instead of forwarding packets, this switch will make targets connections to be killed.

### `--half-duplex`

If your router has some builtin protection against spoofing do not worry, you can go **half duplex**.

During a MITM, **full duplex** means that you're poisoning both the target machine **and** the router, namely if **T** is the target, **R** is the router and **A** is the attacker, you'll do this:

1. Make **T** believe that **A** is the router.
2. Make **R** believe that **A** is the target.

So you need to send two ARP replies in order to do this.

While we were trying to debug the [issue #45](https://github.com/evilsocket/bettercap/issues/45), we started Wireshark on the target computer ( **T** ) to see if it was receiving correct spoofed ARP replies and we noticed something weird.

The first packet that was sent directly to him ( 1 ) was correctly being received but, as soon as my machine sent packet ( 2 ) to the router ( **R** ), the router itself sent another request to the real ip of **T** asking it again for its mac address, making the full duplex spoofing totally worthless as the packet sent from the router invalidated the ARP cache of the target and fixed it.
