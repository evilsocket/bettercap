# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

# http://stackoverflow.com/questions/891537/detect-number-of-cpus-installed
module System
  extend self
  def cpu_count
    return Java::Java.lang.Runtime.getRuntime.availableProcessors if defined? Java::Java
    return File.read('/proc/cpuinfo').scan(/^processor\s*:/).size if File.exist? '/proc/cpuinfo'
    require 'win32ole'
    WIN32OLE.connect("winmgmts://").ExecQuery("select * from Win32_ComputerSystem").NumberOfProcessors
  rescue LoadError
    Integer `sysctl -n hw.ncpu 2>/dev/null` rescue 4
  end
end
