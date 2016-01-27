# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require 'bettercap/firewalls/base'
require 'bettercap/shell'

module BetterCap
module Firewalls
# OSX Firewall class.
class OSX < Base
  # If +enabled+ is true will enable packet forwarding, otherwise it will
  # disable it.
  def enable_forwarding(enabled)
    Shell.execute("sysctl -w net.inet.ip.forwarding=#{enabled ? 1 : 0}")
  end

  # If +enabled+ is true will enable packet icmp_echo_ignore_broadcasts, otherwise it will
  # disable it.
  def enable_icmp_bcast(enabled)
    Shell.execute("sysctl -w net.inet.icmp.bmcastecho=#{enabled ? 1 : 0}")
  end

  # Return true if packet forwarding is currently enabled, otherwise false.
  def forwarding_enabled?
    Shell.execute('sysctl net.inet.ip.forwarding').strip.split(' ')[1] == '1'
  end

  # This method is ignored on OSX.
  def enable_send_redirects(enabled); end

  # If +enabled+ is true, the PF firewall will be enabled, otherwise it will
  # be disabled.
  def enable(enabled)
    begin
      Shell.execute("pfctl -#{enabled ? 'e' : 'd'} >/dev/null 2>&1")
    rescue; end
  end

  # Apply the +r+ BetterCap::Firewalls::Redirection port redirection object.
  def add_port_redirection( r )
    # create the pf config file
    config_file = "/tmp/bettercap_pf_#{Process.pid}.conf"

    File.open( config_file, 'a+t' ) do |f|
      f.write "rdr pass on #{r.interface} proto #{r.protocol} from any to any port #{r.src_port} -> #{r.dst_address} port #{r.dst_port}\n"
    end

    # load the rule
    Shell.execute("pfctl -f #{config_file} >/dev/null 2>&1")
    # enable pf
    enable true
  end

  # Remove the +r+ BetterCap::Firewalls::Redirection port redirection object.
  def del_port_redirection( r )
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
end
end
end
