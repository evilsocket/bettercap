require 'rake'

VERSION_FILENAME = 'lib/bettercap/version.rb'

def proxy!( enabled = true )
  service = "Wi-Fi"

  if enabled
    address = `ifconfig en0 | grep netmask | cut -d ' ' -f 2`.strip
    port = 8080

    `sudo networksetup -setwebproxy '#{service}' #{address} #{port} off`
    `sudo networksetup -setwebproxystate '#{service}' off`
    `sudo networksetup -setwebproxystate '#{service}' on`
  else
    `sudo networksetup -setwebproxystate '#{service}' off`
  end
end

def get_current_version
  current_version = nil
  data = File.read( VERSION_FILENAME )
  if data =~ /VERSION\s+=\s+'([^']+)'/i
    current_version = $1
  end
  raise 'Could not extract current version.' if current_version.nil?
  current_version
end

def change_version( currentv, newv )
  puts "@ Upgrading from '#{currentv}' to '#{newv}' ..."

  data = File.read( VERSION_FILENAME )
  data = data.gsub( currentv, newv )
  File.open( VERSION_FILENAME, 'w') {
    |file| file.puts data
  }
end

namespace :util do
  task :sync do
    puts "@ Synchronizing codebase with GEM installation ..."
    `rm -rf *.gem`
    `gem build bettercap.gemspec`
    `sudo gem install --no-rdoc --no-ri --local *.gem`
  end

  task :release do
    current_version = get_current_version
    raise 'Current version is not a beta.' unless current_version.end_with?'b'

    next_version = current_version.gsub('b','')

    change_version( current_version, next_version )
    current_version = next_version

    puts "@ Pushing to github ..."
    sh "git add #{VERSION_FILENAME}"
    sh "git commit -m \"Version bump to #{current_version}\""
    sh "git push"

    Rake::Task["util:sync"].invoke

    puts "@ Uploading GEM ..."

    sh "gem push bettercap-#{current_version}.gem"
    `rm -rf *.gem`

    parts = current_version.split('.').map(&:to_i)
    parts[parts.size-1] += 1
    next_version = parts.join('.')+'b'

    change_version( current_version, next_version )

    puts "@ Pushing to github ..."
    sh "git add #{VERSION_FILENAME}"
    sh "git commit -m \"Version bump to #{next_version}\""
    sh "git push"

    Rake::Task["util:sync"].invoke
  end
end

namespace :test do
  task :discovery do
    `sudo arp -ad`
    system("clear && sudo bettercap --no-spoofing --no-discovery")
  end

  task :proxy do
    proxy!

    begin
      system( "clear && sudo bettercap --no-discovery --no-spoofing --proxy --proxy-module injectjs --js-data 'alert(123);'" )
    rescue
    ensure
      proxy! false
    end
  end

  task :dns do
    File.open('/tmp/hosts','w'){ |f| f.write("local .*google\\.com\n") }
    system("clear && sudo bettercap --no-spoofing --no-discovery --dns /tmp/hosts")
  end
end
