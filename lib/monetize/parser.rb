module Monetize
  class Parser
    MULTIPLIER_SUFFIXES = { 'K' => 3, 'M' => 6, 'B' => 9, 'T' => 12 }
    MULTIPLIER_SUFFIXES.default = 0
    MULTIPLIER_REGEXP = /^(.*?\d)(#{MULTIPLIER_SUFFIXES.keys.join('|')})\b([^\d]*)$/i

    DEFAULT_DECIMAL_MARK = '.'.freeze
    DEFAULT_MINOR = "00".freeze

    private_constant :DEFAULT_MINOR

    @@original_currency_symbols = {
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
      '₱'  => 'PHP'
    }.freeze

    class << self
      def currency_symbols
        @@currency_symbols ||= @@original_currency_symbols.dup
      end

      def register_currency_symbol(symbol, iso_code)
        currency_symbols[symbol] = iso_code

        reset_currency_symbol_regex
      end

      def unregister_currency_symbol(symbol)
        currency_symbols.delete(symbol)
        reset_currency_symbol_regex
      end

      def reset_currency_symbols!
        @@currency_symbols = @@original_currency_symbols.dup
        reset_currency_symbol_regex
      end

      def currency_symbol_regex
        @@currency_symbol_regex ||= /(?<![A-Z])(#{currency_symbols.keys.map { |key| Regexp.escape(key) }.join('|')})(?![A-Z])/i
      end

      def reset_currency_symbol_regex
        @@currency_symbol_regex = nil
      end
    end

    def initialize(input, fallback_currency = Money.default_currency, options = {})
      @input = input.to_s.strip
      @fallback_currency = fallback_currency
      @options = options
    end

    def parse
      multiplier_exp, input = extract_multiplier

      num = input.gsub(/(?:^#{currency.symbol}|[^\d.,'-]+)/, '')

      negative, num = extract_sign(num)

      amount = to_big_decimal(normalize_number(num))
      amount = apply_multiplier(multiplier_exp, amount)
      amount = apply_sign(negative, amount)

      [amount, currency]
    end

    private

    def normalize_number(num)
      clean_num = num.sub(/[\.|,]$/, "")

      extract_major_minor(clean_num).join(DEFAULT_DECIMAL_MARK)
    end

    def to_big_decimal(value)
      BigDecimal(value)
    rescue ::ArgumentError => err
      fail ParseError, err.message
    end

    attr_reader :input, :fallback_currency, :options

    def currency
      @currency ||= Money::Currency.wrap(parse_currency)
    end

    def parse_currency
      computed_currency = compute_currency_from_iso_code
      computed_currency ||= compute_currency_from_symbol if assume_from_symbol?
      computed_currency ||= fallback_currency || Money.default_currency

      raise Money::Currency::UnknownCurrency unless computed_currency

      computed_currency
    end

    def compute_currency_from_iso_code
      Money::Currency.find(input[/[A-Z]{2,3}/])
    end

    def compute_currency_from_symbol
      match = input.match(self.class.currency_symbol_regex)

      self.class.currency_symbols[match.to_s] if match
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

    def remove_separator(num, separator)
      num.gsub(separator, "")
    end

    def extract_major_minor(num)
      used_delimiters = num.scan(/[^\d]/).uniq

      case used_delimiters.length
      when 0
        [num, DEFAULT_MINOR]
      when 1
        extract_major_minor_with_single_delimiter(num, used_delimiters.first)
      when 2
        thousands_separator, decimal_mark = used_delimiters
        num = remove_separator(num, thousands_separator)

        split_major_minor(num, decimal_mark)
      else
        fail ParseError, 'Invalid amount'
      end
    end

    def minor_has_correct_decimal_places_for_currency?(minor)
      minor.length == currency.decimal_places
    end

    def extract_major_minor_with_single_delimiter(num, delimiter)
      if expect_whole_subunits?
        possible_major, possible_minor = split_major_minor(num, delimiter)

        if minor_has_correct_decimal_places_for_currency?(possible_minor)
          return [possible_major, possible_minor]
        end
      elsif delimiter == currency.decimal_mark
        return split_major_minor(num, delimiter)
      elsif Monetize.enforce_currency_delimiters && delimiter == currency.thousands_separator
        return [remove_separator(num, delimiter), DEFAULT_MINOR]
      end

      extract_major_minor_with_tentative_delimiter(num, delimiter)
    end

    def extract_major_minor_with_tentative_delimiter(num, delimiter)
      if num.scan(delimiter).length > 1
        # Multiple matches; treat as thousands separator
        return [remove_separator(num, delimiter), DEFAULT_MINOR]
      end

      possible_major, possible_minor = split_major_minor(num, delimiter)

      # Doesn't look like thousands separator
      is_decimal_mark = possible_minor.length != 3 ||
                        possible_major.length > 3 ||
                        possible_major.to_i == 0 ||
                        (!expect_whole_subunits? && delimiter == ".")

      return [possible_major, possible_minor] if is_decimal_mark

      ["#{possible_major}#{possible_minor}", DEFAULT_MINOR]
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

      splits[1] ||= DEFAULT_MINOR

      splits
    end
  end
end
