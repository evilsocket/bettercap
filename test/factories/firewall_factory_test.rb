require 'minitest/autorun'
require 'bettercap/factories/firewall_factory'

class FirewallFactoryTest < MiniTest::Test
  # TODO: Fix the tests for the Mac and Linux firewall initialization. Right now
  # they are being created in a way which executes a shell command, causing
  # tests to fail.

  # def test_mac_firewall
  #   FirewallFactory.clear_firewall
  #
  #   override_ruby_platform('darwin') do
  #     firewall = FirewallFactory.get_firewall
  #     assert_equal firewall.class, OSXFirewall
  #   end
  # end

  # def test_linux_firewall
  #   FirewallFactory.clear_firewall
  #
  #   override_ruby_platform('linux') do
  #     firewall = FirewallFactory.get_firewall
  #     assert_equal firewall.class, LinuxFirewall
  #   end
  # end

  def test_unknown_firewall
    BetterCap::FirewallFactory.clear_firewall

    override_ruby_platform('ms') do
      assert_raises BetterCap::Error do
        BetterCap::FirewallFactory.get_firewall
      end
    end
  end

  private

  def override_ruby_platform(platform)
    actual_platform = RUBY_PLATFORM

    begin
      redefine_const :RUBY_PLATFORM, platform
      yield
    ensure
      redefine_const :RUBY_PLATFORM, actual_platform
    end
  end

  def redefine_const(const, value)
    Object.send(:remove_const, const) if Object.const_defined?(const)
    Object.const_set(const, value)
  end
end
