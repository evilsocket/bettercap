module BetterCap
module Network
# This class is responsible for reading the computer ARP table.
class NdpReader
  # Parse the Ndp cache searching for the given IP +address+ and return its
  # MAC if found, otherwise nil.
  def self.find_address( address )
    self.parse_cache(address) do |ip,mac|
      if ip == address
        return mac
      end
    end
    nil
  end

  private

  # Read the computer NDP cache and parse each line, it will yield each
  # ip and mac address it will be able to extract.
  def self.parse_cache(address)
    iface = Context.get.iface.name
    Shell.ndp.split("\n").each do |line|
      if line.include?(address) && line.include?(iface)
        m = line.split
        ip = m[0]
        hw = Target.normalized_mac( m[4] )
        if hw != 'FF:FF:FF:FF:FF:FF'
          yield( ip, hw )
        end
      end
    end
  end
end
end
end
