require 'minitest/autorun'
require 'test_helper'
require 'firewalls/osx'
require 'helpers/mock_shell'

class OSXFirewallTest < MiniTest::Test
  def test_enabling_forwarding
    firewall = stubbed_firewall(BetterCap::OSXFirewall).new
    result = firewall.enable_forwarding true

    assert_equal result, 'sysctl -w net.inet.ip.forwarding=1'
  end

  def test_disabling_forwarding
    firewall = stubbed_firewall(BetterCap::OSXFirewall).new
    result = firewall.enable_forwarding false

    assert_equal result, 'sysctl -w net.inet.ip.forwarding=0'
  end

  def test_enabling_icmp_broadcast
    firewall = stubbed_firewall(BetterCap::OSXFirewall).new
    result = firewall.enable_icmp_bcast true

    assert_equal result, 'sysctl -w net.inet.icmp.bmcastecho=1'
  end

  def test_disabling_icmp_broadcast
    firewall = stubbed_firewall(BetterCap::OSXFirewall).new
    result = firewall.enable_icmp_bcast false

    assert_equal result, 'sysctl -w net.inet.icmp.bmcastecho=0'
  end

  def test_whether_forwarding_is_enabled
    expected_output = 'net.inet.ip.forwarding: 1'
    MockShell.stub :execute, expected_output do

      firewall = stubbed_firewall(BetterCap::OSXFirewall).new
      result = firewall.forwarding_enabled?

      assert result

    end
  end

  def test_whether_forwarding_is_disabled
    expected_output = 'net.inet.ip.forwarding: 0'
    MockShell.stub :execute, expected_output do

      firewall = stubbed_firewall(BetterCap::OSXFirewall).new
      result = firewall.forwarding_enabled?

      refute result

    end
  end

  def test_enabling_the_firewall
    firewall = stubbed_firewall(BetterCap::OSXFirewall).new
    result = firewall.enable true

    assert_equal result, 'pfctl -e >/dev/null 2>&1'
  end

  def test_disabling_the_firewall
    firewall = stubbed_firewall(BetterCap::OSXFirewall).new
    result = firewall.enable false

    assert_equal result, 'pfctl -d >/dev/null 2>&1'
  end
end
