=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

module BetterCap
module Parsers
# CC parser.
class CreditCard < Base
  PARSERS = [
    # All major cards.
    /(?:4[0-9]{12}(?:[0-9]{3})?|5[1-5][0-9]{14}|6011[0-9]{12}|3(?:0[0-5]|[68][0-9])[0-9]{11}|3[47][0-9]{13})/m,
    # American Express
    /(3[47][0-9]{13})/m,
    # Diners Club
    /(3(?:0[0-5]|[68][0-9])[0-9]{11})/m,
    # Discover
    /(6011[0-9]{12})/m,
    # MasterCard
    /(5[1-5][0-9]{14})/m,
    # Visa
    /(4[0-9]{12}(?:[0-9]{3})?)/m
  ].freeze

  def on_packet( pkt )
    begin
      payload = pkt.to_s
      PARSERS.each do |expr|
        matches = payload.scan( expr )
        matches.each do |m|
          StreamLogger.log_raw( pkt, 'CREDITCARD', m ) if luhn?(m)
        end
        break unless matches.empty?
      end
    rescue; end
  end

  # Validate +cc+ with Lughn algorithm.
  def luhn?(cc)
    digits = cc.split(//).map(&:to_i)
    last   = digits.pop

    products = digits.reverse.map.with_index do |n,i|
        i.even? ? n*2 : n*1
    end.reverse
    sum = products.inject(0) { |t,p| t + p.to_s.split(//).map(&:to_i).inject(:+) }
    checksum = 10 - (sum % 10)
    checksum == 10 ? 0 : checksum

    ( last == checksum )
  end

end
end
end
