# encoding: utf-8

module Monetize
  class Parser
    CURRENCY_SYMBOLS = {
      '$'  => 'USD',
      '€'  => 'EUR',
      '£'  => 'GBP',
      '₤'  => 'GBP',
      'R$' => 'BRL',
      'RM' => 'MYR',
      'Rp' => 'IDR',
      'R'  => 'ZAR',
      '¥'  => 'JPY',
      'C$' => 'CAD',
      '₼'  => 'AZN',
      '元' => 'CNY',
      'Kč' => 'CZK',
      'Ft' => 'HUF',
      '₹'  => 'INR',
      '₽'  => 'RUB',
      '₺'  => 'TRY',
      '₴'  => 'UAH',
      'Fr' => 'CHF',
      'zł' => 'PLN',
      '₸'  => 'KZT',
      "₩"  => 'KRW',
      'S$' => 'SGD',
      'HK$'=> 'HKD',
      'NT$'=> 'TWD',
      '₱'  => 'PHP',
    }

    MULTIPLIER_SUFFIXES = { 'K' => 3, 'M' => 6, 'B' => 9, 'T' => 12 }
    MULTIPLIER_SUFFIXES.default = 0

    def initialize(input, fallback_currency, options)
      raise NotImplementedError, 'Monetize::Parser subclasses must implement #initialize'
    end

    def parse
      raise NotImplementedError, 'Monetize::Parser subclasses must implement #parse'
    end
  end
end
