![logo](http://www.bettercap.org/assets/img/navbar-logo.png)

http://www.bettercap.org/

[![Gem Version](https://badge.fury.io/rb/bettercap.svg)](http://badge.fury.io/rb/bettercap) [![Code Climate](https://codeclimate.com/github/evilsocket/bettercap/badges/gpa.svg)](https://codeclimate.com/github/evilsocket/bettercap) [![Join the chat at https://gitter.im/evilsocket/bettercap](https://badges.gitter.im/evilsocket/bettercap.svg)](https://gitter.im/evilsocket/bettercap?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
---

**bettercap** is a complete, modular, portable and easily extensible **MITM** tool and framework with every kind of diagnostic
and offensive feature you could need in order to perform a man in the middle attack.

Contact me at:

- Twitter: [@evilsocket](https://twitter.com/evilsocket)
- Email: evilsocket@gmail.com

Before submitting issues, please read the relevant [section](http://www.bettercap.org/docs/contribute/) in the documentation.

Installation
============

**Stable Release ( GEM )**

    gem install bettercap

**From Source**

    git clone https://github.com/evilsocket/bettercap
    cd bettercap
    gem build bettercap.gemspec
    sudo gem install bettercap*.gem

Dependencies
============

All dependencies will be automatically installed through the GEM system, in some case you might need to install some system
dependency in order to make everything work:

    sudo apt-get install ruby-dev libpcap-dev

This should solve issues such as [this one](https://github.com/evilsocket/bettercap/issues/22).

Documentation and Examples
============

Please refer to the [official website](http://www.bettercap.org/docs/).
