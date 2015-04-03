# encoding: utf-8

class Hash
  def to_money(currency = nil)
    Money.new(self[:cents], self[:currency] || currency || Money.default_currency)
  end
end
