**bettercap** is a complete, modular, portable and easily extensible **MITM** tool and framework with every kind of diagnostic
and offensive feature you could need in order to perform a man in the middle attack.

Before submitting issues, please read the relevant [section](https://www.bettercap.org/docs/contribute/) in the documentation.

<table>
    <tr>
        <th>Version</th>
        <td>
          <a href="https://badge.fury.io/rb/bettercap" target="_blank">
            <img src="https://badge.fury.io/rb/bettercap.svg"/>
          </a>
        </td>
    </tr>
    <tr>
        <th>Homepage</th>
        <td><a href="https://www.bettercap.org/">https://www.bettercap.org/</a></td>
    </tr>
    <tr>
        <th>Blog</th>
        <td><a href="https://www.bettercap.org/blog/">https://www.bettercap.org/blog/</a></td>
    <tr>
        <th>Github</th>
        <td><a href="https://github.com/evilsocket/bettercap">https://github.com/evilsocket/bettercap</a></td>
     <tr/>
    <tr>
        <th>Documentation</th>
        <td><a href="https://www.bettercap.org/docs/">https://www.bettercap.org/docs/</a></td>
    </tr>
    <tr>
        <th>Code Documentation</th>
        <td>
          <a href="http://www.rubydoc.info/github/evilsocket/bettercap">http://www.rubydoc.info/github/evilsocket/bettercap</a>
          &nbsp;
          <a href="https://codeclimate.com/github/evilsocket/bettercap" target="_blank">
            <img src="https://codeclimate.com/github/evilsocket/bettercap/badges/gpa.svg"/>
          </a>
        </td>
    </tr>
    <tr>
       <th>Author</th>
       <td><a href="https://www.evilsocket.net/">Simone Margaritelli</a> (<a href="https://twitter.com/evilsocket">@evilsocket</a>)</td>
    </tr>
    <tr>
        <th>Twitter</th>
        <td><a href="https://twitter.com/bettercap">@bettercap</a></td>
    </tr>
    <tr>
        <th>Chat</th>
        <td>
          <a href="https://gitter.im/evilsocket/bettercap" target="_blank">
            <img src="https://badges.gitter.im/evilsocket/bettercap.svg"/>
          </a>
        </td>
    </tr>
    <tr>
        <th>Copyright</th>
        <td>2015-2016 Simone Margaritelli</td>
    </tr>
    <tr>
        <th>License</th>
        <td>GPL v3.0 - (see LICENSE file)</td>
    </tr>
</table>

Installation
============

**Dependencies**

All dependencies will be automatically installed through the GEM system but in some case you might need to install some system
dependency in order to make everything work:

    sudo apt-get install build-essential ruby-dev libpcap-dev

This should solve issues such as [this one](https://github.com/evilsocket/bettercap/issues/22) or [this one](https://github.com/evilsocket/bettercap/issues/100).

**Stable Release ( GEM )**

    gem install bettercap

**From Source**

    git clone https://github.com/evilsocket/bettercap
    cd bettercap
    gem build bettercap.gemspec
    sudo gem install bettercap*.gem

**Installation on Kali Linux**

Kali Linux has bettercap packaged and added to the **kali-rolling** repositories. To install bettercap and all dependencies in one fell swoop on the latest version of Kali Linux:
    
    apt-get update
    apt-get dist-upgrade
    apt-get install bettercap

Documentation and Examples
============

Please refer to the [official website](https://www.bettercap.org/docs/).
