require './lib/bettercap/version'

Gem::Specification.new do |gem|
  gem.name = %q{bettercap}
  gem.version = BetterCap::VERSION
  gem.license = 'GPL3'
  gem.description = %q{A complete, modular, portable and easily extensible MITM framework.}
  gem.summary = %q{A complete, modular, portable and easily extensible MITM framework.}

  gem.authors = ['Simone Margaritelli']
  gem.email = %q{evilsocket@gmail.com}
  gem.homepage = %q{http://github.com/evilsocket/bettercap}

  gem.add_dependency( 'colorize', '~> 0.7.5' )
  gem.add_dependency( 'packetfu', '~> 1.1.10' )
  gem.add_dependency( 'pcaprub', '~> 0.12.0' )

  gem.files = Dir.glob("lib/**/*") + Dir.glob("bin/*") + [
      "LICENSE",
      "README.md",
      "bettercap.gemspec",
      "example_proxy_module.rb"
  ]
  gem.require_paths = ["lib"]

  gem.executables   = %w(bettercap)
  gem.rdoc_options = ["--charset=UTF-8"]
end
