HTTP/HTTPS
============

Bettercap is shipped with both a HTTP and a HTTPS transparent proxies that you can use to manipulate HTTP and HTTPS traffic at runtime ( inject javascripts into the targets visited pages, replace the images, etc ).
By default the builtin proxies won't do anything but logging HTTP(S) requests, but if you specify a `--proxy-module` argument you will be able to load one of the builtin modules ( or your own ) and manipulate HTTP traffic as you like.

Builtin modules are:

* InjectJS ( `--proxy-module injectjs` ) : Used to inject javascript code/files inside HTML pages.
* InjectCSS ( `--proxy-module injectcss` ) : Used to inject CSS code/files inside HTML pages.
* InjectHTML ( `--proxy-module injecthtml` ) : Used to inject HTML code inside HTML pages.

HTTP/HTTPS proxy modules might want additional command line arguments, it's always a good idea to look at their specific help menus:

`bettercap --proxy-module NAME -h`


## Sample Module

You can easily implement a module to inject data into pages or just inspect the requests/responses creating a ruby file and passing it to bettercap with the `--proxy-module` argument, the following is a sample module that injects some contents into the title tag of each html page, you can find other examples modules in the [proxy modules dedicated repository](https://github.com/evilsocket/bettercap-proxy-modules).

<script src="https://gist.github.com/evilsocket/bfdb1af7e6bf9d9d0bfe.js"></script>

## HTTP

### SSL Stripping

SSL stripping is a technique introduced by [Moxie Marlinspike](http://www.thoughtcrime.org/software/sslstrip/) during BlackHat DC 2009, the website description of this technique goes like:

> It will transparently hijack HTTP traffic on a network, watch for HTTPS links and redirects, then map those links into either look-alike HTTP links or homograph-similar HTTPS links.

Long story short, this technique will replace every **https** link in webpages the target is browsing with **http** ones so, if a page would normally look like:

    ... <a href="https://www.facebook.com/">Login</a> ...

During a SSL stripping attack its HTML code will be modified as:

    ... <a href="http://www.facebook.com/">Login</a> ...

Being the **man in the middle**, this allow us to sniff and modify pages that normally we wouldn't be able to even see.

### HSTS Bypass

SSL stripping worked quite well until 2010, when the **HSTS** specification was introduced, Wikipedia says:

> **HTTP Strict Transport Security** (HSTS) is a web security policy mechanism which helps to protect websites against protocol downgrade attacks and cookie hijacking. It allows web servers to declare that web browsers (or other complying user agents) should only interact with it using secure HTTPS connections, and never via the insecure HTTP protocol. HSTS is an IETF standards track protocol and is specified in RFC 6797.

Moreover HSTS policies have been prebuilt into major browsers meaning that now, even with a SSL stripping attack running, the browser will
connect to HTTPS anyway, even if the *http://* schema is specified, making the attack itself useless.

<center>
  ![network mitm](/_static/img/with-hsts.png)
  <br/>
  <small>Picture credits to <a href="https://scotthelme.co.uk/ssl-does-not-make-site-secure/" target="_blank">Scott Helme</a></small>
</center>

For this reason, [Leonardo Nve Egea](http://www.slideshare.net/Fatuo__/offensive-exploiting-dns-servers-changes-blackhat-asia-2014) presented **sslstrip+** ( or sslstrip2 ) during BlackHat Asia 2014.
This tool was an improvement over the original Moxie's version, specifically created to bypass HSTS policies.
Since HSTS rules most of the time are applied on a per-hostname basis, the trick is to downgrade HTTPS links to HTTP **and** to prepend some custom sub domain name to them. Every resulting link won't be valid for any DNS server, but since we're MITMing we can resolve these hostnames anyway.

Let's take the previous example page:

    ... <a href="https://www.facebook.com/">Login</a> ...

A HSTS bypass attack will change it to something like:

    ... <a href="http://wwww.facebook.com/">Login</a> ...
<center><small>Notice that https has been downgraded to http and <strong>www</strong> replaced with <strong>wwww</strong> ).</small></center>

When the "victim" will click on that link, no HSTS rule will be applied ( since there's no rule for such subdomain we just created ) and the MITM software ( BetterCap in our case ^_^ ) will take care of the DNS resolution, allowing us to see and alter the traffic we weren't supposed to see.

<center>
  ![network mitm](/_static/img/sslstrip2.png)
</center>

### Demonstration

The following video demonstrates how to perform SSL Stripping and HSTS Bypass attacks in order to capture the Facebook login credentials of a specific target.

<iframe width="100%" height="400" src="https://www.youtube.com/embed/BfvoONHXuQA" frameborder="0" allowfullscreen></iframe>

## HTTPS

### Server Name Indication

> Server Name Indication (SNI) is an extension to the TLS computer networking protocol by which a client indicates which hostname it is attempting to connect to at the start of the handshaking process. This allows a server to present multiple certificates on the same IP address and TCP port number and hence allows multiple secure (HTTPS) websites (or any other Service over TLS) to be served off the same IP address without requiring all those sites to use the same certificate.

Using the **SNI** callback, BetterCAP's HTTPS proxy is able to detect the upstream server host using the following logic:

1. Client connects to a HTTPS server while being transparently proxied by us.
2. We catch the upstream server hostname in the **SNI** callback.
3. We pause the callback, connect to the upstream server and fetch its certificate.
4. We resign that certificate with our own CA and use it to serve the client.

This way, as long as you have BetterCap's certification authority PEM file installed on the target device, you won't see any warnings or errors since correct certificate will be spoofed in realtime.

There're a couple of caveats of course:

1. If you don't install either bettercap's CA or your custom CA on the target device, you'll see warnings and errors anyway (duh!).
2. Every application using [certificate/public Key pinning](https://www.owasp.org/index.php/Certificate_and_Public_Key_Pinning) will detect the attack even with the CA installed.

### Installing Certification Authority

Since version 1.4.4 BetterCAP comes with a pre made certification authority file which is extracted in your home directory the first time you'll launch the HTTPS proxy, you'll find the file as:

    ~/.bettercap/bettercap-ca.pem

You'll need to install this file on the device you want to transparently proxy HTTPS connection for, the procedure is OS specific as mentioned in a previous blog post:

* **iOS** - http://kb.mit.edu/confluence/pages/viewpage.action?pageId=152600377
* **iOS Simulator** - https://github.com/ADVTOOLS/ADVTrustStore#how-to-use-advtruststore
* **Java** - http://docs.oracle.com/cd/E19906-01/820-4916/geygn/index.html
* **Android/Android Simulator** - http://wiki.cacert.org/FAQ/ImportRootCert#Android_Phones_.26_Tablets
* **Windows** - http://windows.microsoft.com/en-ca/windows/import-export-certificates-private-keys#1TC=windows-7
* **Mac OS X** - https://support.apple.com/kb/PH7297?locale=en_US
* **Ubuntu/Debian** - http://askubuntu.com/questions/73287/how-do-i-install-a-root-certificate/94861#94861
* **Mozilla Firefox** - https://wiki.mozilla.org/MozillaRootCertificate#Mozilla_Firefox
* **Chrome on Linux** - https://code.google.com/p/chromium/wiki/LinuxCertManagement

Once you've done, just use the `--proxy-https` bettercap command line argument to enable the HTTPS proxy and you're ready to go.

<hr/>

## Options

### `--proxy-upstream-address ADDRESS`

If set, only requests coming from this server address will be redirected to the HTTP/HTTPS proxies.

### `--allow-local-connections`

Allow direct connections to the proxy instance, default to `false`.

### `--proxy`

Enable HTTP proxy and redirects all HTTP requests to it, default to `false`.

### `--proxy-port PORT`

Set HTTP proxy port, default to `8080`.

### `--no-sslstrip`

Disable SSL stripping and HSTS bypass.

### `--proxy-module MODULE`

Ruby proxy module to load, either a custom file or one of the following: `injectcss`, `injecthtml`, `injectjs`.

### `--http-ports PORT1,PORT2`

Comma separated list of HTTP ports to redirect to the proxy, default to `80`.

### `--proxy-https`

Enable HTTPS proxy and redirects all HTTPS requests to it, default to `false`.

### `--proxy-https-port PORT`

Set HTTPS proxy port, default to `8083`.

### `--proxy-pem FILE`

Use a custom PEM CA certificate file for the HTTPS proxy, default to `~/.bettercap/bettercap-ca.pem`.

### `--https-ports PORT1,PORT2`

Comma separated list of HTTPS ports to redirect to the proxy, default to `443`.
