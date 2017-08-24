Spoofing
============

As previously described in the introduction section, spoofing is the very heart of every MITM attack. These options will determine which spoofing technique to use and how to use it.

BetterCap already includes an [ARP spoofer](https://en.wikipedia.org/wiki/ARP_spoofing) ( working both in full duplex and half duplex mode which is the default ), a **DNS** spoofer and **the first, fully working and completely automatized [ICMP DoubleDirect spoofer](https://blog.zimperium.com/doubledirect-zimperium-discovers-full-duplex-icmp-redirect-attacks-in-the-wild/) in the world**

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

### `--full-duplex`

Enable full-duplex MITM, this will make bettercap attack both the target(s) and the router.
