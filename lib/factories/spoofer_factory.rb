=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
class SpooferFactory
  def SpooferFactory.available
    avail = []
    Dir.foreach( File.dirname(__FILE__) + '/../spoofers/') do |file|
      if file =~ /.rb/
        avail << file.gsub('.rb','').upcase
      end
    end
    avail
  end

  def SpooferFactory.get_by_name(name)
    avail = SpooferFactory.available

    raise "Invalid spoofer name '#{name}'!" unless avail.include? name

    name.downcase!

    require_relative "../spoofers/#{name}"

    Kernel.const_get("#{name.capitalize}Spoofer").new
  end
end
