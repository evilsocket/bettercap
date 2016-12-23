require 'rake'

VERSION_FILENAME = 'lib/bettercap/version.rb'

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
  desc "Build a GEM from the current source code and install it locally."
  task :sync do
    puts "@ Synchronizing codebase with GEM installation ..."
    `rm -rf *.gem`
    `gem build bettercap.gemspec`
    `sudo gem install --no-rdoc --no-ri --local *.gem`
  end

  desc "Upgrade version to stable, push to github and upload the new GEM release."
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

    Rake::Task["util:sync"].invoke
  end

  desc "Print a markdown changelog for the current release."
  task :changelog do
    feats = []
    fixes = []
    style = []

    puts "@ Fetching remote tags ...\n\n"

    `git fetch --tags`
    lines = `git log \`git describe --tags --abbrev=0\`..HEAD --oneline`.split("\n")
    lines.each do |line|
      if line =~ /^[^\s]+\s+(.+)$/
        msg = $1.gsub( /([^\s]*[A-Z][^\s]*[A-Z][^\s]*)/, '`\1`' ).gsub( /([a-z]+_[a-z]+)/, '`\1`' )
        dwn = msg.downcase

        next if dwn.include?('version bump') or dwn.include?('rake')

        if dwn.include?('fix')
          fixes << msg
        elsif dwn.include?('new')
          feats << msg
        else
          style << msg
        end
      end
    end

    puts "Changelog"
    puts "===\n\n"

    puts "**New Features**\n\n"
    feats.each do |m|
      puts "* #{m}"
    end

    puts "\n**Fixes**\n\n"
    fixes.each do |m|
      puts "* #{m}"
    end

    puts "\n**Code Style**\n\n"
    style.each do |m|
      puts "* #{m}"
    end
    puts "\n"
  end
end

task :default => 'util:sync'
