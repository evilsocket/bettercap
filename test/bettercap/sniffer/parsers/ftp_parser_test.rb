require 'minitest/autorun'
require 'test_helper'
require 'packetfu'
require 'bettercap/sniffer/parsers/ftp'

class FtpParserTest < MiniTest::Test
  def setup
    # The pcap file for the FTP tests was taken from the Practical Packet
    # Analysis GitHub repo: https://github.com/markofu/pcaps
    @packets = ftp_packets
    @parser = BetterCap::FtpParser.new
  end

  def test_parsing_ftp_packets_with_no_user_data
    silence do |output|
      @parser.on_packet @packets[0]
      assert output.length == 0
    end
  end

  def test_parsing_ftp_packets_with_user_data
    silence do |output|
      @parser.on_packet @packets[4]
      refute output.length == 0
    end
  end
end
