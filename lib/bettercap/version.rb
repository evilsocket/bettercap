=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
module BetterCap
  VERSION = '1.1.3'
  BANNER = File.read( File.dirname(__FILE__) + '/banner' ).gsub( '#VERSION#', "v#{VERSION}")
end
