Installation
============

BetterCap comes packaged as a **Ruby** gem, meaning you will need a Ruby interpreter ( >= 1.9 ) and a RubyGems environment installed. Moreover, it is **fully compatible with GNU/Linux, Mac OS X and OpenBSD platforms**.

### Dependencies

All Ruby dependencies will be automatically installed through the GEM system, however some of the GEMS need native libraries in order to compile:

    sudo apt-get install build-essential ruby-dev libpcap-dev

### Installing on Kali Linux

Kali Linux has bettercap packaged and added to the **kali-rolling** repositories. To install bettercap and all dependencies in one fell swoop on the latest version of Kali Linux:

    apt-get update
    apt-get install bettercap    

### Stable Release ( GEM )

You can easily install bettercap using the `gem install GEMNAME` command:

    gem install bettercap

To update to a newer release:

    gem update bettercap

If you have trouble installing bettercap read the following sections about dependencies.

<div class="admonition note">
<p class="admonition-title">Note</p>
<p>If you installed bettercap using a RVM installation, you will need to execute it using <strong>rvmsudo</strong>:<br/>
  <code>rvmsudo bettercap ...</code><br/>
Otherwise, if you installed it globally ( <code>sudo gem install bettercap</code> ) you can use <strong>sudo</strong>:<br/>
  <code>sudo bettercap ...</code>
</p>
</div>

### Development Release

Instead of the stable release, you can also clone the source code from the github repository, this will give you
all the latest and **experimental** features, but remember that you're using a potentially unstable release:

    git clone https://github.com/evilsocket/bettercap
    cd bettercap
    bundle install
    gem build bettercap.gemspec
    sudo gem install bettercap*.gem

### Quick Start

Once you've installed bettercap, quickly get started with:

    bettercap --help

The help menu will show you every available command line option and a few examples.
