class Hash
  def to_money(currency = nil)
    money_hash = self.respond_to?(:with_indifferent_access) ? self.with_indifferent_access : self

    hash_currency = if money_hash[:currency].is_a?(Hash)
                      money_hash[:currency][:iso_code]
                    elsif money_hash[:currency_iso] && !money_hash[:currency_iso].empty?
                      money_hash[:currency_iso]
                    else
                      money_hash[:currency]
                    end

    Money.new(money_hash[:cents] || money_hash[:fractional], hash_currency || currency || Money.default_currency)
  end
end
