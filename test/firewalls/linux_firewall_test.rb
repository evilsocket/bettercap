require 'minitest/autorun'
require 'test_helper'
require 'bettercap/firewalls/linux'
require 'helpers/mock_shell'

class OSXFirewallTest < MiniTest::Test
  def test_enabling_forwarding
    firewall = stubbed_firewall(BetterCap::LinuxFirewall).new
    result = firewall.enable_forwarding true

    assert_equal result, 'echo 1 > /proc/sys/net/ipv4/ip_forward'
  end

  def test_disabling_forwarding
    firewall = stubbed_firewall(BetterCap::LinuxFirewall).new
    result = firewall.enable_forwarding false

    assert_equal result, 'echo 0 > /proc/sys/net/ipv4/ip_forward'
  end

  def test_enabling_icmp_broadcast
    firewall = stubbed_firewall(BetterCap::LinuxFirewall).new
    result = firewall.enable_icmp_bcast true

    assert_equal result, 'echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts'
  end

  def test_disabling_icmp_broadcast
    firewall = stubbed_firewall(BetterCap::LinuxFirewall).new
    result = firewall.enable_icmp_bcast false

    assert_equal result, 'echo 0 > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts'
  end

  def test_whether_forwarding_is_enabled
    expected_output = '1'
    MockShell.stub :execute, expected_output do

      firewall = stubbed_firewall(BetterCap::LinuxFirewall).new
      result = firewall.forwarding_enabled?

      assert result

    end
  end

  def test_whether_forwarding_is_disabled
    expected_output = '0'
    MockShell.stub :execute, expected_output do

      firewall = stubbed_firewall(BetterCap::LinuxFirewall).new
      result = firewall.forwarding_enabled?

      refute result

    end
  end

  def test_enabling_the_firewall
    firewall = stubbed_firewall(BetterCap::LinuxFirewall).new
    result = firewall.enable true

    assert_equal result, 'pfctl -e >/dev/null 2>&1'
  end

  def test_disabling_the_firewall
    firewall = stubbed_firewall(BetterCap::LinuxFirewall).new
    result = firewall.enable false

    assert_equal result, 'pfctl -d >/dev/null 2>&1'
  end
end
