require 'minitest/autorun'
require 'test_helper'
require 'bettercap/sniffer/parsers/ftp'
require 'packetfu'

class BaseParserTest < MiniTest::Test
  def setup
    @packets = parsed_packets
    @parser = BetterCap::BaseParser.new
  end

  # The base parser has no parsers by default, so it shouldn't be writing
  # anything to STDOUT.
  def test_parsing_packets
    silence do |output|
      @parser.on_packet @packets.first
      assert output.length == 0
    end
  end
end
