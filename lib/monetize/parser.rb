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

    def initialize(input, fallback_currency = Money.default_currency, options = {})
      @input = input.to_s.strip
      @fallback_currency = fallback_currency
      @options = options
    end

    def parse_cents(currency)
      multiplier_exp, input = extract_multiplier

      num = input.gsub(/(?:^#{currency.symbol}|[^\d.,'-]+)/, '')

      negative, num = extract_sign(num)

      num.chop! if num =~ /[\.|,]$/

      major, minor = extract_major_minor(num, currency)

      major, minor = apply_multiplier(multiplier_exp, major.to_i, minor)

      cents = major.to_i * currency.subunit_to_unit

      cents += set_minor_precision(minor, currency)

      apply_sign(negative, cents)
    end

    def parse_currency
      computed_currency = nil
      computed_currency = compute_currency if assume_from_symbol?
      computed_currency ||= input[/[A-Z]{2,3}/]

      computed_currency || fallback_currency || Money.default_currency
    end

    private

    attr_reader :input, :fallback_currency, :options

    def assume_from_symbol?
      options.fetch(:assume_from_symbol) { Monetize.assume_from_symbol }
    end

    def apply_multiplier(multiplier_exp, major, minor)
      major *= 10**multiplier_exp
      minor = minor.to_s + ('0' * multiplier_exp)
      shift = minor[0...multiplier_exp].to_i
      major += shift
      minor = (minor[multiplier_exp..-1] || '')
      [major, minor]
    end

    def apply_sign(negative, cents)
      negative ? cents * -1 : cents
    end

    def compute_currency
      matches = input.match(currency_symbol_regex)
      CURRENCY_SYMBOLS[matches[:symbol]] if matches
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

    def set_minor_precision(minor, currency)
      if Money.infinite_precision
        (BigDecimal(minor) / (10**minor.size)) * currency.subunit_to_unit
      elsif minor.size < currency.decimal_places
        (minor + ('0' * currency.decimal_places))[0, currency.decimal_places].to_i
      elsif minor.size > currency.decimal_places
        if minor[currency.decimal_places, 1].to_i >= 5
          minor[0, currency.decimal_places].to_i + 1
        else
          minor[0, currency.decimal_places].to_i
        end
      else
        minor.to_i
      end
    end

    def split_major_minor(num, delimiter)
      major, minor = num.split(delimiter)
      [major, minor || '00']
    end

    def currency_symbol_regex
      /\A[\+|\-]?(?<symbol>#{regex_safe_symbols})/
    end
  end
end
