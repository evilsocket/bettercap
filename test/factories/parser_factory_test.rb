require 'minitest/autorun'
require 'factories/parser_factory'

class ParserFactoryTest < MiniTest::Test
  def test_getting_available_parsers
    available_parsers = BetterCap::ParserFactory.available
    assert available_parsers.include?('FTP')
  end

  def test_successful_cmdline_parser_name
    parsers = BetterCap::ParserFactory.from_cmdline('ftp,https')
    assert_equal parsers, ['FTP', 'HTTPS']
  end

  def test_failed_cmdline_parser_name
    assert_raises BetterCap::Error do
      BetterCap::ParserFactory.from_cmdline 'unknown'
    end
  end

  def test_no_cmdline_parser_provided
    assert_raises BetterCap::Error do
      BetterCap::ParserFactory.from_cmdline nil
    end
  end

  def test_successfully_loading_parsers
    loaded = BetterCap::ParserFactory.load_by_names 'FTP'
    assert_equal loaded.first.class, BetterCap::FtpParser
  end

  def test_unsuccessfully_loading_parsers
    loaded = BetterCap::ParserFactory.load_by_names 'unknown'
    assert_empty loaded
  end
end
