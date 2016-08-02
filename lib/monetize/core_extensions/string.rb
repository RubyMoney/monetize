# encoding: utf-8

class String
  def to_money(currency = nil)
    Monetize.parse!(self, currency)
  end

  def to_currency
    Money::Currency.new(self)
  end
end
