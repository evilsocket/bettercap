require 'rake'

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

namespace :util do
  task :sync do
    puts "@ Synchronizing codebase with GEM installation ..."
    `rm -rf *.gem`
    `gem build bettercap.gemspec`
    `sudo gem install --no-rdoc --no-ri --local *.gem`
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
