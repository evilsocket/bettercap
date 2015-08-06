require 'minitest/autorun'
require 'shell'

class ShellTest < MiniTest::Test
  def test_successful_command_execution
    result = BetterCap::Shell.execute "echo 'BetterCap is awesome!'"
    assert_equal result, "BetterCap is awesome!\n"
  end

  def test_failed_command_execution
    assert_raises BetterCap::Error do
      BetterCap::Shell.execute 'false'
    end
  end
end
