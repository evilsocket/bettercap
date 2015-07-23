require 'minitest/autorun'
require 'factories/spoofer_factory'

class SpooferFactoryTest < MiniTest::Test
  def test_getting_available_parsers
    spoofers = SpooferFactory.available
    assert spoofers.include?('ARP')
  end

  def test_unsuccessful_name
    assert_raises BetterCap::Error do
      SpooferFactory.get_by_name 'unknown'
    end
  end
end
