require 'bettercap/options'

class OptionsTest < MiniTest::Test
  def setup
    @iface = Pcap.lookupdev
    @tempfile = Tempfile.new('foo')

    argv = [
      '-I', "eth1",
      '-S', 'NONE',
      '-T', 'target',
      '-O', 'log',
      '-D',
      '-L',
      '--sniffer-pcap', @tempfile.path,
      '--sniffer-filter', 'expression',
      '--no-discovery'
    ]

    @options = BetterCap::Options.new(argv)
  end

  def test_interface
    assert_equal @options[:iface], 'eth1'
  end

  def test_spoofer
    assert_equal @options[:spoofer], 'NONE'
  end

  def test_target
    assert_equal @options[:target], 'target'
  end

  def test_log
    assert_equal @options[:logfile], 'log'
  end

  def test_debug
    assert @options[:debug], 'debug should be true'
  end

  def test_local
    assert @options[:local], 'local should be true'
    assert @options[:sniffer], 'sniffer should be true'
  end

  def test_sniffer
    @options[:sniffer] = false
    opt = BetterCap::Options.new(['-X'])
    assert opt[:sniffer], 'sniffer should be true'
  end

  def test_sniffer_pcap
    assert_equal @options[:sniffer_pcap], @tempfile.path
  end

  def test_sniffer_filter
    assert_equal @options[:sniffer_filter], 'expression'
  end
end
