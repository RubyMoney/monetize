# encoding: utf-8

require 'money'
require 'monetize/core_extensions'
require 'monetize/version'
require 'collection'

module Monetize
  CURRENCY_SYMBOLS = {
    '$'    => 'USD',
    '€'    => 'EUR',
    '£'    => 'GBP',
    '₤'    => 'GBP',
    'R$'   => 'BRL',
    'R'    => 'ZAR',
    '¥'    => 'JPY',
    'C$'   => 'CAD'
  }

  MULTIPLIER_SUFFIXES = {
    'K'    => 3,
    'M'    => 6,
    'B'    => 9,
    'T'    => 12
  }
  MULTIPLIER_SUFFIXES.default = 0
  MULTIPLIER_REGEXP = Regexp.new(format('^(.*?\d)(%s)\b([^\d]*)$', MULTIPLIER_SUFFIXES.keys.join('|')), 'i')

  # Class methods
  class << self
    # @attr_accessor [true, false] assume_from_symbol Use this to enable the
    #   ability to assume the currency from a passed symbol
    attr_accessor :assume_from_symbol

    # Monetize uses the delimiters set in the currency to separate integers from
    # decimals, and to ignore thousands separators. In some corner cases,
    # though, it will try to determine the correct separator by itself. Set this
    # to true to enforce the delimiters set in the currency all the time.
    attr_accessor :enforce_currency_delimiters
  end

  def self.parse(input, currency = Money.default_currency, options = {})
    input = input.to_s.strip

    computed_currency = if options.fetch(:assume_from_symbol) { assume_from_symbol }
                          compute_currency(input)
                        else
                          input[/[A-Z]{2,3}/]
                        end

    currency = computed_currency || currency || Money.default_currency
    currency = Money::Currency.wrap(currency)

    fractional = extract_cents(input, currency)
    Money.new(fractional, currency)
  end

  def self.parse_collection(input, currency = Money.default_currency, options = {})
    Collection.parse(input, currency, options)
  end

  def self.from_string(value, currency = Money.default_currency)
    value = BigDecimal.new(value.to_s)
    from_bigdecimal(value, currency)
  end

  def self.from_fixnum(value, currency = Money.default_currency)
    currency = Money::Currency.wrap(currency)
    value *= currency.subunit_to_unit
    Money.new(value, currency)
  end

  def self.from_float(value, currency = Money.default_currency)
    value = BigDecimal.new(value.to_s)
    from_bigdecimal(value, currency)
  end

  def self.from_bigdecimal(value, currency = Money.default_currency)
    currency = Money::Currency.wrap(currency)
    value *= currency.subunit_to_unit
    value = value.round unless Money.infinite_precision
    Money.new(value, currency)
  end

  def self.from_numeric(value, currency = Money.default_currency)
    case value
    when Fixnum
      from_fixnum(value, currency)
    when Numeric
      value = BigDecimal.new(value.to_s)
      from_bigdecimal(value, currency)
    else
      fail ArgumentError, "'value' should be a type of Numeric"
    end
  end

  def self.extract_cents(input, currency = Money.default_currency)
    multiplier_exp, input = extract_multiplier(input)

    num = input.gsub(/[^\d.,'-]/, '')

    negative, num = extract_sign(num)

    num.chop! if num.match(/[\.|,]$/)

    major, minor = extract_major_minor(num, currency)

    cents = major.to_i * currency.subunit_to_unit

    cents, minor = apply_multiplier(multiplier_exp, cents, minor)

    cents += set_minor_precision(minor, currency)

    apply_sign(negative, cents)
  end

  private

  def self.apply_multiplier(multiplier_exp, cents, minor)
    cents *= (10**multiplier_exp)
    minor = minor.to_s + ('0' * multiplier_exp)
    shift = minor[0...multiplier_exp].to_i * 100
    cents += shift
    minor = (minor[multiplier_exp..-1] || '')
    [cents, minor]
  end

  def self.apply_sign(negative, cents)
    negative ? cents * -1 : cents
  end

  def self.contains_currency_symbol?(amount)
    amount =~ currency_symbol_regex
  end

  def self.compute_currency(amount)
    if contains_currency_symbol?(amount)
      matches = amount.match(currency_symbol_regex)
      CURRENCY_SYMBOLS[matches[:symbol]]
    else
      amount[/[A-Z]{2,3}/]
    end
  end

  def self.extract_major_minor(num, currency)
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
      fail ArgumentError, 'Invalid currency amount'
    end
  end

  def self.extract_major_minor_with_single_delimiter(num, currency, delimiter)
    if delimiter == currency.decimal_mark
      split_major_minor(num, delimiter)
    elsif enforce_currency_delimiters and delimiter == currency.thousands_separator
      [num.gsub(delimiter, ''), 0]
    else
      extract_major_minor_with_tentative_delimiter(num, delimiter)
    end
  end

  def self.extract_major_minor_with_tentative_delimiter(num, delimiter)
    if num.scan(delimiter).length > 1
      # Multiple matches; treat as thousands separator
      [num.gsub(delimiter, ''), '00']
    else
      possible_major, possible_minor = split_major_minor(num, delimiter)

      if possible_minor.length != 3 or possible_major.length > 3 or delimiter == '.'
        # Doesn't look like thousands separator
        [possible_major, possible_minor]
      else
        ["#{possible_major}#{possible_minor}", '00']
      end
    end
  end

  def self.extract_multiplier(input)
    if (matches = MULTIPLIER_REGEXP.match(input))
      multiplier_suffix = matches[2].upcase
      [MULTIPLIER_SUFFIXES[multiplier_suffix], "#{$1}#{$3}"]
    else
      [0, input]
    end
  end

  def self.extract_sign(input)
    result = (input =~ /^-+(.*)$/ or input =~ /^(.*)-+$/) ? [true, $1] : [false, input]
    fail ArgumentError, 'Invalid currency amount (hyphen)' if result[1].include?('-')
    result
  end

  def self.regex_safe_symbols
    CURRENCY_SYMBOLS.keys.map { |key| Regexp.escape(key) }.join('|')
  end

  def self.set_minor_precision(minor, currency)
    if Money.infinite_precision
      (BigDecimal.new(minor) / (10**minor.size)) * currency.subunit_to_unit
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

  def self.split_major_minor(num, delimiter)
    major, minor = num.split(delimiter)
    minor = '00' unless minor
    [major, minor]
  end

  def self.currency_symbol_regex
    /\A[\+|\-]?(?<symbol>#{regex_safe_symbols})/
  end
end
