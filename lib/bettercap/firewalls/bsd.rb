# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : https://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

module BetterCap
module Firewalls
# *BSD and OSX Firewall class.
class BSD < Base
  def initialize
    @filename = "/tmp/bettercap_pf_#{Process.pid}.conf"
  end

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
    Shell.execute("pfctl -#{enabled ? 'e' : 'd'} >/dev/null 2>&1")
  rescue
  end

  # Apply the +r+ BetterCap::Firewalls::Redirection port redirection object.
  def add_port_redirection( r )
    # create the pf config file
    File.open( @filename, 'a+t' ) do |f|
      f.write "#{gen_rule(r)}\n"
    end
    # load the rule
    Shell.execute("pfctl -f #{@filename} >/dev/null 2>&1")
    # enable pf
    enable true
  end

  # Remove the +r+ BetterCap::Firewalls::Redirection port redirection object.
  def del_port_redirection( r )
    # remove the redirection rule from the existing file
    rule = gen_rule(r)
    rules = File.readlines(@filename).collect(&:strip).reject(&:empty?)
    rules.delete(rule)

    # no other rules, delete file and disable firewall.
    if rules.empty?
      File.delete(@filename)
      enable false
    # other rules are present in the file, update it
    else
      File.open( @filename, 'w+t' ) do |f|
        rules.each do |rule|
          f.write "#{rule}\n"  
        end
      end
      # let the firewall know we updated the file
      Shell.execute("pfctl -f #{@filename} >/dev/null 2>&1")
    end
  rescue
  end

  private

  # Convert +r+ to BSD firewall rule
  def gen_rule( r )
    "rdr pass on #{r.interface} " +
      "proto #{r.protocol} " +
      "from any to #{r.src_address.nil? ? 'any' : r.src_address} " +
      "port #{r.src_port} -> #{r.dst_address} port #{r.dst_port}"
  end
end
end
end
