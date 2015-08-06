require 'bettercap/helpers/mock_shell'
require 'securerandom'

# Override the `shell` private method of the firewall to return the mock
# shell. The mock shell's purpose is to capture any system calls made and
# verify that they were received.
def stubbed_firewall(target)
  Class.new(target) do
    define_method(:shell) do
      MockShell
    end
  end
end

# Allow for a way to silence calls during test runs.
#
# This redirects STDOUT to /dev/null for any methods
# called inside the block of this method.
def silence(output_file_name = SecureRandom.hex)
  captured_output = Tempfile.new output_file_name
  BetterCap::Logger.logfile = captured_output

  $stdout = File.new('/dev/null', 'w')
  yield captured_output
ensure
  $stdout = STDOUT
end

# Methods for getting PacketFu::Packet objects out of pcap files.

def parsed_packets
  packets_with_filename 'packets'
end

def ftp_packets
  packets_with_filename 'ftp'
end

def http_packets
  packets_with_filename 'http'
end

private

def packets_with_filename(filename)
  PacketFu::PcapFile.read_packets(File.join(File.dirname(__FILE__),"pcap/#{filename}.pcap"))
end
