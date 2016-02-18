# How To Contribute

As any other open source projects, there're many ways you can contribute to bettercap depending on your skills as a developer or will to help as a user, but first 
of all let me thank you for your help! <3

### Submitting Issues

If you find bugs or inconsistencies while using bettercap, you can create an **Issue** using the [GitHub Issue tracker](https://github.com/evilsocket/bettercap/issues), but before doing that please make sure that:

* You are using a relatively new Ruby version ( >= 1.9 ) : `ruby -v`.
* Your GEM environment is configured properly and updated : `sudo gem update`.    
* You are using the latest version of bettercap : `bettercap --check-updates`.
* The bug you're reporting is actually related to bettercap and not to one of the other GEMs.

Once you've gone through this list, open an issue and please give us as much as informations as possible in order for us to fix the bug as soon as possible:

* Your OS version.
* Ruby version you're using.
* Full output of the error ( exception backtrace, error message, etc ).
* Your network configuration: `ifconfig -a`

Also, you should attach to the issue a debug log that you can generate with:

    [sudo|rvmsudo] bettercap [arguments you are using for testing] --debug --log=debug.log

Wait for the error to happen then close bettercap and paste the **debug.log** file inside the issue.

### Pull Requests

If you know how to code in Ruby and have ideas to improve bettercap, you're very welcome to send us pull requests, we'll be happy to merge them whenever they comply to the following rules:

* You have at least manually tested your code, ideally you've created actual tests for it.
* Respect our coding standard, 2 spaces indentation and modular code.
* There're no conflicts with the current dev branch.
* Your commit messages are enough explanatory to us.

There're plenty of things you can to do improve the software:

* Implement a new proxy module and push it to the [dedicated repository](https://github.com/evilsocket/bettercap-proxy-modules).
* Implement a new [Spoofer module](https://github.com/evilsocket/bettercap/blob/master/lib/bettercap/spoofers/arp.rb).
* Implement a new [Sniffer credentials parser](https://github.com/evilsocket/bettercap/blob/master/lib/bettercap/sniffer/parsers/post.rb).
* Fix, extend or improve the core.
