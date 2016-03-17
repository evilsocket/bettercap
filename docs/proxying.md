About Proxying
============

Bettercap is shipped with a HTTP/HTTPS ( with **SSL Stripping** and **HSTS Bypass** ) and raw TCP transparent proxies that you can use to manipulate HTTP/HTTPS or low level TCP traffic at runtime, for instance you could use the HTTP/HTTPS proxy to inject javascripts into the targets visited pages ( [BeEF](http://beefproject.com/) would be a great choice :D ), replace all the images, etc or use the TCP one for other protocols ( downgrade encryption with STARTTLS, dump custom protocols and so forth.

![proxy](/_static/img/proxy.png)

Once one or more proxies are enabled, bettercap will take care of the spoofing and the firewall rules needed in order to redirect your targets' traffic to the proxy itself.

By default the builtin proxies won't do anything but logging all the requests, additionally you can specify a "module" to use and you will be able to load one of the builtin plugins ( or your own ) and manipulate all the traffic as you like.
