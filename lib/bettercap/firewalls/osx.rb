=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require 'bettercap/base/ifirewall'
require 'bettercap/shell'

class OSXFirewall < IFirewall
  def enable_forwarding(enabled)
    shell.execute("sysctl -w net.inet.ip.forwarding=#{enabled ? 1 : 0}")
  end

  def enable_icmp_bcast(enabled)
    shell.execute("sysctl -w net.inet.icmp.bmcastecho=#{enabled ? 1 : 0}")
  end

  def forwarding_enabled?
    shell.execute('sysctl net.inet.ip.forwarding').strip.split(' ')[1] == '1'
  end

  def enable(enabled)
    begin
      shell.execute("pfctl -#{enabled ? 'e' : 'd'} >/dev/null 2>&1")
    rescue; end
  end

  def add_port_redirection( iface, proto, from, addr, to )
    # create the pf config file
    config_file = "/tmp/bettercap_pf_#{Process.pid}.conf"

    File.open( config_file, 'a+t' ) do |f|
      f.write "rdr pass on #{iface} inet proto #{proto} from any to any port #{from} -> #{addr} port #{to}\n"
    end

    # load the rule
    shell.execute("pfctl -f #{config_file} >/dev/null 2>&1")
    # enable pf
    enable true
  end

  def del_port_redirection( iface, proto, from, addr, to )
    # FIXME: This should search for multiple rules inside the
    # file and remove only this one.

    # disable pf
    enable false

    begin
      # remove the pf config file
      File.delete( "/tmp/bettercap_pf_#{Process.pid}.conf" )
    rescue
    end

  end

  private

  def shell
    Shell
  end
end
