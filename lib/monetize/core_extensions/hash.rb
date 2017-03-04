# encoding: utf-8

class Hash
  def to_money(currency = nil)
    hash_currency = self[:currency].is_a?(Hash) ? self[:currency][:iso_code] : self[:currency]
    Money.new(self[:cents] || self[:fractional], hash_currency || currency || Money.default_currency)
  end
end
