Sniffing & Credentials Harvesting
============

The builtin sniffer is currently able to dissect and print from the network ( or from a previously captured PCAP file ) the following informations:

- URLs being visited.
- HTTPS hosts being visited.
- HTTP POSTed data.
- HTTP Basic and Digest authentications.
- HTTP Cookies.
- FTP credentials.
- IRC credentials.
- POP, IMAP and SMTP credentials.
- NTLMv1/v2 ( HTTP, SMB, LDAP, etc ) credentials.
- DICT Protocol credentials.
- MPD Credentials.
- NNTP Credentials.
- DHCP messages and authentication.
- REDIS login credentials.
- RLOGIN credentials.
- SNPP credentials.
- And more!

> New parsers are implemented almost on a regular basis for each new release, for a full and updated list check the `SNIFFING` section in the `bettercap --help` menu.

<hr/>

#### `-X, --sniffer`

Enable sniffer.

#### `-L, --local`

By default bettercap will only parse packets coming from/to other addresses on the network, if you also want to process packets being sent or received from your own computer you can use this option ( NOTE: will enable the sniffer ).

##### Example

Use bettercap as a simple local network sniffer:

`sudo bettercap --local` or `sudo bettercap -L`

#### `--sniffer-source FILE`

Load packets from the specified PCAP file instead of the network interface ( NOTE: will enable the sniffer ).

##### Example

Use the *capture.pcap* file in your home directory as a packets source:

`sudo bettercap --sniffer-source ~/capture.pcap`

#### `--sniffer-output FILE`

Save all packets to the specified PCAP file ( NOTE: will enable the sniffer ).

##### Example

Spoof the whole network and save every packet to the *capture.pcap* file in your home directory:

`sudo bettercap --sniffer-output ~/capture.pcap`

#### `--sniffer-filter EXPRESSION`

Configure the sniffer to use this [BPF filter](http://biot.com/capstats/bpf.html) ( NOTE: will enable the sniffer ).

##### Example

Spoof the whole network but only sniff HTTP traffic:

`sudo bettercap --sniffer-filter "tcp port http"`

#### `-P, --parsers PARSERS`

Comma separated list of packet parsers to enable, `*` for all ( NOTE: will enable the sniffer ), available: `COOKIE`, `CREDITCARD`, `DHCP`, `DICT`, `FTP`, `HTTPAUTH`, `HTTPS`, `IRC`, `MAIL`, `MPD`, `MYSQL`, `NNTP`, `NTLMSS`, `PGSQL`, `POST`, `REDIS`, `RLOGIN`, `SNMP`, `SNPP`, `URL`, `WHATSAPP`, default to `*`.

#### `--custom-parser EXPRESSION`

Use a custom regular expression in order to capture and show sniffed data ( NOTE: will enable the sniffer ).

##### Example

Spoof the whole network and extract data from packets containing the "password" word:

`sudo bettercap --custom-parser ".*password.*"`
