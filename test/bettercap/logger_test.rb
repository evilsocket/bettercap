require 'minitest/autorun'
require 'test_helper'
require 'logger'

class LoggerTest < MiniTest::Test
  def test_writing_with_a_logfile
    silence do |output|
      BetterCap::Logger.write 'Test log message'
      assert_equal output.read, "Test log message\n"
    end
  end
end
