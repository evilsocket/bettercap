require 'minitest/autorun'
require 'network'

class NetworkTest < MiniTest::Test
  def test_valid_ip_address
    valid = Network.is_ip? '127.0.0.1'
    assert valid
  end

  def test_invalid_ip_address
    addresses = ['bad-ip', '255.255.255.255.255', '255.255', '999.999.999.999', 123]
    addresses.each { |address| refute Network.is_ip?(address) }
  end
end
