HTTP
============

You want to serve your custom javascript files on the network? Maybe you wanna inject some custom script or image into HTTP responses using a [transparent proxy module](/proxying.html) but you got no public server to use? **no worries dude** :D  
A builtin HTTP server comes with bettercap, allowing you to serve custom contents from your own machine without installing and configuring other softwares such as Apache, nginx or lighttpd.

<hr/>

#### `--httpd`

Enable HTTP server, default to `false`.

#### `--httpd-port PORT`

Set HTTP server port, default to `8081`.

#### `--httpd-path PATH`

Set HTTP server path, default to `./`.
