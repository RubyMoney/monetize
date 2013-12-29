class Symbol
  def to_currency
    Money::Currency.new(self)
  end
end
