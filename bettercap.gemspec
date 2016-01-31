require './lib/bettercap/version'

Gem::Specification.new do |gem|
  gem.name = %q{bettercap}
  gem.version = BetterCap::VERSION
  gem.license = 'GPL-3.0'
  gem.summary = %q{A complete, modular, portable and easily extensible MITM framework.}
  gem.description = %q{BetterCap is the state of the art, modular, portable and easily extensible MITM framework featuring ARP, DNS and ICMP spoofing, sslstripping, credentials harvesting and more.}
  gem.required_ruby_version = '>= 1.9'


  gem.authors = ['Simone Margaritelli']
  gem.email = %q{evilsocket@gmail.com}
  gem.homepage = %q{http://github.com/evilsocket/bettercap}

  gem.add_dependency( 'colorize', '~> 0.7.5' )
  gem.add_dependency( 'packetfu', '~> 1.1', '>= 1.1.10' )
  gem.add_dependency( 'pcaprub', '~> 0.12.0' )
  gem.add_dependency( 'network_interface', '~> 0.0.1' )
  gem.add_dependency( 'net-dns', '~> 0.8.0' )
  gem.add_dependency( 'rubydns', '~> 1.0', '>= 1.0.3' )

  gem.files = Dir.glob("*.md") +
              Dir.glob("lib/**/*") +
              Dir.glob("bin/**/*")

  gem.require_paths = ["lib"]

  gem.executables   = %w(bettercap)
  gem.rdoc_options = ["--charset=UTF-8"]
end
