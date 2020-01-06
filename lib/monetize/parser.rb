# encoding: utf-8

module Monetize
  class Parser
    CURRENCY_SYMBOLS = {
      '$'  => 'USD',
      '€'  => 'EUR',
      '£'  => 'GBP',
      '₤'  => 'GBP',
      'R$' => 'BRL',
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
    }

    MULTIPLIER_SUFFIXES = { 'K' => 3, 'M' => 6, 'B' => 9, 'T' => 12 }
    MULTIPLIER_SUFFIXES.default = 0
    MULTIPLIER_REGEXP = Regexp.new(format('^(.*?\d)(%s)\b([^\d]*)$', MULTIPLIER_SUFFIXES.keys.join('|')), 'i')

    DEFAULT_DECIMAL_MARK = '.'.freeze

    def initialize(input, fallback_currency = Money.default_currency, options = {})
      @input = input.to_s.strip
      @fallback_currency = fallback_currency
      @options = options
    end

    def parse
      currency = Money::Currency.wrap(parse_currency)

      multiplier_exp, input = extract_multiplier

      num = input.gsub(/(?:^#{currency.symbol}|[^\d.,'-]+)/, '')

      negative, num = extract_sign(num)

      num.chop! if num =~ /[\.|,]$/

      major, minor = extract_major_minor(num, currency)

      amount = BigDecimal([major, minor].join(DEFAULT_DECIMAL_MARK))
      amount = apply_multiplier(multiplier_exp, amount)
      amount = apply_sign(negative, amount)

      [amount, currency]
    end

    private

    attr_reader :input, :fallback_currency, :options

    def parse_currency
      computed_currency = nil
      computed_currency = compute_currency if assume_from_symbol?
      computed_currency ||= input[/[A-Z]{2,3}/]

      computed_currency || fallback_currency || Money.default_currency
    end

    def assume_from_symbol?
      options.fetch(:assume_from_symbol) { Monetize.assume_from_symbol }
    end

    def apply_multiplier(multiplier_exp, amount)
      amount * 10**multiplier_exp
    end

    def apply_sign(negative, amount)
      negative ? amount * -1 : amount
    end

    def compute_currency
      match = input.match(currency_symbol_regex)
      CURRENCY_SYMBOLS[match.to_s] if match
    end

    def extract_major_minor(num, currency)
      used_delimiters = num.scan(/[^\d]/).uniq

      case used_delimiters.length
      when 0
        [num, 0]
      when 2
        thousands_separator, decimal_mark = used_delimiters
        split_major_minor(num.gsub(thousands_separator, ''), decimal_mark)
      when 1
        extract_major_minor_with_single_delimiter(num, currency, used_delimiters.first)
      else
        fail ParseError, 'Invalid amount'
      end
    end

    def extract_major_minor_with_single_delimiter(num, currency, delimiter)
      if delimiter == currency.decimal_mark
        split_major_minor(num, delimiter)
      elsif Monetize.enforce_currency_delimiters && delimiter == currency.thousands_separator
        [num.gsub(delimiter, ''), 0]
      else
        extract_major_minor_with_tentative_delimiter(num, delimiter)
      end
    end

    def extract_major_minor_with_tentative_delimiter(num, delimiter)
      if num.scan(delimiter).length > 1
        # Multiple matches; treat as thousands separator
        [num.gsub(delimiter, ''), '00']
      else
        possible_major, possible_minor = split_major_minor(num, delimiter)

        if possible_minor.length != 3 || possible_major.length > 3 || delimiter == '.'
          # Doesn't look like thousands separator
          [possible_major, possible_minor]
        else
          ["#{possible_major}#{possible_minor}", '00']
        end
      end
    end

    def extract_multiplier
      if (matches = MULTIPLIER_REGEXP.match(input))
        multiplier_suffix = matches[2].upcase
        [MULTIPLIER_SUFFIXES[multiplier_suffix], "#{$1}#{$3}"]
      else
        [0, input]
      end
    end

    def extract_sign(input)
      result = (input =~ /^-+(.*)$/ || input =~ /^(.*)-+$/) ? [true, $1] : [false, input]
      fail ParseError, 'Invalid amount (hyphen)' if result[1].include?('-')
      result
    end

    def regex_safe_symbols
      CURRENCY_SYMBOLS.keys.map { |key| Regexp.escape(key) }.join('|')
    end

    def split_major_minor(num, delimiter)
      major, minor = num.split(delimiter)
      [major, minor || '00']
    end

    def currency_symbol_regex
      /(?<![A-Z])(#{regex_safe_symbols})(?![A-Z])/i
    end
  end
end
