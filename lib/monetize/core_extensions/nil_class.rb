class NilClass
  def to_money(currency = nil)
    Money.new(nil, currency || Money.default_currency)
  end
end
