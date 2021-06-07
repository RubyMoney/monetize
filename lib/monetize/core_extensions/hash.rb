# encoding: utf-8

class Hash
  def to_money(currency = nil)
    hash_currency = if self[:currency].is_a?(Hash)
                      self[:currency][:iso_code]
                    elsif self[:currency_iso] && !self[:currency_iso].empty?
                      self[:currency_iso]
                    else
                      self[:currency]
                    end

    Money.new(self[:cents] || self[:fractional], hash_currency || currency || Money.default_currency)
  end
end
