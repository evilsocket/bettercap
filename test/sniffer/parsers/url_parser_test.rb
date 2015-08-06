require 'minitest/autorun'
require 'test_helper'
require 'packetfu'
require 'sniffer/parsers/url'

class UrlParserTest < MiniTest::Test
  def setup
    @packets = http_packets
    @parser = BetterCap::UrlParser.new
  end

  def test_parsing_http_packets
    silence do |output|
      @parser.on_packet @packets[3]
      refute output.length == 0
    end
  end

  def test_parsing_http_packets_without_any_urls
    silence do |output|
      @parser.on_packet @packets[0]
      assert output.length == 0
    end
  end
end
