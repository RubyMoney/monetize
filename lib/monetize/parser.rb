# encoding: utf-8

module Monetize
  class Parser
    INITIAL_CURRENCY_SYMBOLS = {
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
    # FIXME: This ignored symbols could be ambiguous or conflict with other symbols
    IGNORED_SYMBOLS = ['kr', 'NIO$', 'UM', 'L', 'oz t', "so'm", 'CUC$'].freeze

    MULTIPLIER_SUFFIXES = { 'K' => 3, 'M' => 6, 'B' => 9, 'T' => 12 }
    MULTIPLIER_SUFFIXES.default = 0
    MULTIPLIER_REGEXP = Regexp.new(format('^(.*?\d)(%s)\b([^\d]*)$', MULTIPLIER_SUFFIXES.keys.join('|')), 'i')

    DEFAULT_DECIMAL_MARK = '.'.freeze

    def self.currency_symbols
      @@currency_symbols ||= Money::Currency.table.reduce(INITIAL_CURRENCY_SYMBOLS.dup) do |memo, (_, currency)|
        symbol = currency[:symbol]
        symbol = currency[:disambiguate_symbol] if symbol && memo.key?(symbol)

        next memo if is_invalid_currency_symbol?(symbol)

        memo[symbol] = currency[:iso_code] unless memo.value?(currency[:iso_code])

        memo
      end.freeze
    end

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

    def self.is_invalid_currency_symbol?(symbol)
      currency_symbol_blank?(symbol) ||
      symbol.include?('.') || # Ignore symbols with dots because they can be confused with decimal marks
      IGNORED_SYMBOLS.include?(symbol) ||
      MULTIPLIER_REGEXP.match?("1#{symbol}") # Ignore symbols that can be confused with multipliers
    end

    def self.currency_symbol_blank?(symbol)
      symbol.nil? || symbol.empty?
    end

    def to_big_decimal(value)
      BigDecimal(value)
    rescue ::ArgumentError => err
      fail ParseError, err.message
    end

    attr_reader :input, :fallback_currency, :options

    def parse_currency
      computed_currency = compute_currency_from_iso_code
      computed_currency ||= compute_currency_from_symbol if assume_from_symbol?

      computed_currency || fallback_currency || Money.default_currency
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

    def compute_currency_from_iso_code
      computed_currency = input[/[A-Z]{2,4}/]

      return unless computed_currency

      computed_currency if self.class.currency_symbols.value?(computed_currency)
    end

    def compute_currency_from_symbol
      match = input.match(currency_symbol_regex)

      self.class.currency_symbols[match.to_s] if match
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
        possible_major, possible_minor = split_major_minor(num, delimiter)

        if minor_has_correct_dp_for_currency_subunit?(possible_minor, currency)
          return [possible_major, possible_minor]
        end
      else
        return split_major_minor(num, delimiter) if delimiter == currency.decimal_mark

        if Monetize.enforce_currency_delimiters && delimiter == currency.thousands_separator
          return [num.gsub(delimiter, ''), 0]
        end
      end

      extract_major_minor_with_tentative_delimiter(num, delimiter)
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
      matches = MULTIPLIER_REGEXP.match(input)

      if matches
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
      self.class.currency_symbols.keys.map { |key| Regexp.escape(key) }.join('|')
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
