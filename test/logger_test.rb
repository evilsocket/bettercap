require 'minitest/autorun'
require 'logger'

class LoggerTest < MiniTest::Test
  def test_writing_with_a_logfile
    file = Tempfile.new('bettercap_temp_logfile')

    Logger.logfile = file
    silence do
      Logger.write 'Test log message'
    end

    assert_equal file.read, "Test log message\n"
    Logger.logfile = nil
  end

  private

  # Allow for a way to silence calls during test runs.
  #
  # This redirects STDOUT to /dev/null for any methods
  # called inside the block of this method.
  def silence
    $stdout = File.new('/dev/null', 'w')
    yield
  ensure
    $stdout = STDOUT
  end
end
