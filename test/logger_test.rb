require 'minitest/autorun'
require 'logger'

class LoggerTest < MiniTest::Test
  def test_writing_with_a_logfile
    file = Tempfile.new('bettercap_temp_logfile')

    Logger.logfile = file
    Logger.write 'Test log message'

    assert_equal file.read, "Test log message\n"
    Logger.logfile = nil
  end
end
