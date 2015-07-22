=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require_relative '../base/ifirewall'
require_relative '../shell'

class OSXFirewall < IFirewall
  def enable_forwarding(enabled)
    if enabled then
      Shell.execute('sysctl -w net.inet.ip.forwarding=1')
    else
      Shell.execute('sysctl -w net.inet.ip.forwarding=0')
    end
  end

  def enable_icmp_bcast(enabled)
    if enabled then
      Shell.execute('sysctl -w net.inet.icmp.bmcastecho=1') 
    else
      Shell.execute('sysctl -w net.inet.icmp.bmcastecho=0')       
    end
  end

  def forwarding_enabled?()
    Shell.execute('sysctl net.inet.ip.forwarding').strip.split(' ')[1] == '1'
  end

  def enable(enabled)
    begin
      if enabled
        Shell.execute('pfctl -e >/dev/null 2>&1')
      else
        Shell.execute('pfctl -d >/dev/null 2>&1')
      end
    rescue
    end
  end

  def add_port_redirection( iface, proto, from, addr, to )
    # create the pf config file
    config_file = "/tmp/bettercap_pf_#{Process.pid}.conf"

    File.open( config_file, 'a+t' ) do |f|
      f.write "rdr on #{iface} inet proto #{proto} to any port #{from} -> #{addr} port #{to}\n"
    end

    # load the rule
    Shell.execute("pfctl -f #{config_file} >/dev/null 2>&1")
    # enable pf
    enable true
  end

  def del_port_redirection( iface, proto, from, addr, to )
    # FIXME: This should search for multiple rules inside the
    # file and remove only this one.

    # disable pf
    enable false
    # remove the pf config file
    File.delete( "/tmp/bettercap_pf_#{Process.pid}.conf" )
  end
end
