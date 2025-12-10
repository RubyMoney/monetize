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

    CURRENCY_SYMBOL_REGEX = /(?<![A-Z])(#{CURRENCY_SYMBOLS.keys.map { |key| Regexp.escape(key) }.join('|')})(?![A-Z])/i
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

      amount = to_big_decimal([major, minor].join(DEFAULT_DECIMAL_MARK))
      amount = apply_multiplier(multiplier_exp, amount)
      amount = apply_sign(negative, amount)

      [amount, currency]
    end

    private

    def to_big_decimal(value)
      BigDecimal(value)
    rescue ::ArgumentError => err
      fail ParseError, err.message
    end

    attr_reader :input, :fallback_currency, :options

    def parse_currency
      computed_currency = nil
      computed_currency = input[/[A-Z]{2,3}/]
      computed_currency = nil unless Monetize::Parser::CURRENCY_SYMBOLS.value?(computed_currency)
      computed_currency ||= compute_currency if assume_from_symbol?

      found = computed_currency || fallback_currency || Money.default_currency
      raise Money::Currency::UnknownCurrency unless found
      found
    end

    def assume_from_symbol?
      options.fetch(:assume_from_symbol) { Monetize.assume_from_symbol }
    end

    def expect_whole_subunits?
      options.fetch(:expect_whole_subunits) { Monetize.expect_whole_subunits }
    end

    def apply_multiplier(multiplier_exp, amount)
      amount * 10**multiplier_exp
    end

    def apply_sign(negative, amount)
      negative ? amount * -1 : amount
    end

    def compute_currency
      match = input.match(CURRENCY_SYMBOL_REGEX)
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

    def minor_has_correct_dp_for_currency_subunit?(minor, currency)
      minor.length == currency.subunit_to_unit.to_s.length - 1
    end

    def extract_major_minor_with_single_delimiter(num, currency, delimiter)
      if expect_whole_subunits?
        _possible_major, possible_minor = split_major_minor(num, delimiter)
        if minor_has_correct_dp_for_currency_subunit?(possible_minor, currency)
          split_major_minor(num, delimiter)
        else
          extract_major_minor_with_tentative_delimiter(num, delimiter)
        end
      else
        if delimiter == currency.decimal_mark
          split_major_minor(num, delimiter)
        elsif Monetize.enforce_currency_delimiters && delimiter == currency.thousands_separator
          [num.gsub(delimiter, ''), 0]
        else
          extract_major_minor_with_tentative_delimiter(num, delimiter)
        end
      end
    end

    def extract_major_minor_with_tentative_delimiter(num, delimiter)
      if num.scan(delimiter).length > 1
        # Multiple matches; treat as thousands separator
        [num.gsub(delimiter, ''), '00']
      else
        possible_major, possible_minor = split_major_minor(num, delimiter)

        # Doesn't look like thousands separator
        is_decimal_mark = possible_minor.length != 3 ||
                          possible_major.length > 3 ||
                          possible_major.to_i == 0 ||
                          (!expect_whole_subunits? && delimiter == '.')

        if is_decimal_mark
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

    def split_major_minor(num, delimiter)
      splits = num.split(delimiter)
      fail ParseError, 'Invalid amount (multiple delimiters)' if splits.length > 2

      [splits[0], splits[1] || '00']
    end
  end
end
