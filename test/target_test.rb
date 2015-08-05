require 'minitest/autorun'
require 'target'

class TestTarget < MiniTest::Test
  def setup
    @target = BetterCap::Target.new('127.0.0.1', '08:00:20')
  end

  def test_initialization
    assert_equal @target.ip, '127.0.0.1'
    assert_equal @target.mac, '08:00:20'
    assert_equal @target.vendor, 'Oracle'
  end

  def test_setting_mac
    @target.mac = '7F:D0:BD:8B:60:DA'
    assert_equal @target.mac, '7F:D0:BD:8B:60:DA'
  end

  def test_string_coercion
    @target.mac = '08:00:20'
    assert_equal @target.to_s, '127.0.0.1 : 08:00:20 ( Oracle )'
  end
end
