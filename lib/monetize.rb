# encoding: utf-8

require "money"
require "monetize/core_extensions"
require "monetize/version"

module Monetize

  NEGATIVE_NUMBER_RE = /\A-|-\z/

  # Class methods
  class << self
    # @attr_accessor [true, false] assume_from_symbol Use this to enable the
    #   ability to assume the currency from a passed symbol
    attr_accessor :assume_from_symbol
  end

  def self.parse(input, currency = Money.default_currency)
    input = input.to_s.strip

    computed_currency = compute_currency(input)
    if not assume_from_symbol
      computed_currency = input[/[A-Z]{2,3}/] || currency
    end

    currency = computed_currency || currency || Money.default_currency
    currency = Money::Currency.wrap(currency)

    fractional = extract_cents(input, currency)
    Money.new(fractional, currency)
  end

  def self.compute_currency(input)
    known_symbols = {"$" => "USD", "€" => "EUR", "£" => "GBP", "R" => "ZAR", "R\\$" => "BRL"}
    matches = []
    known_symbols.each do |k, v|
      if input =~ /^#{k}/
        matches << k
      end
    end
    if matches.empty?
      input[/[A-Z]{2,3}/]
    else
      best_match = find_best_match(matches)
      known_symbols[best_match]
    end
  end

  def self.find_best_match(matches)
    max = matches[0].length
    best = matches[0]
    (1...matches.length).each do |i|
      if matches[i].length > max
        best = matches[i]
        max = best.length
      end
    end
    best
  end

  def self.from_string(value, currency = Money.default_currency)
    value = BigDecimal.new(value.to_s)
    from_bigdecimal(value, currency)
  end

  def self.from_fixnum(value, currency = Money.default_currency)
    currency = Money::Currency.wrap(currency)
    value = value * currency.subunit_to_unit
    Money.new(value, currency)
  end

  def self.from_float(value, currency = Money.default_currency)
    value = BigDecimal.new(value.to_s)
    from_bigdecimal(value, currency)
  end

  def self.from_bigdecimal(value, currency = Money.default_currency)
    currency = Money::Currency.wrap(currency)
    value = value * currency.subunit_to_unit
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
      raise ArgumentError, "'value' should be a type of Numeric"
    end
  end

  def self.extract_cents(input, currency = Money.default_currency)
    @original_number = num = input.gsub(/[^\d.,'-]/, '')

    decimal_char = currency.decimal_mark

    num = strip_negative_symbols(num)

    num.sub!(/[\.,]\z/, '')

    used_delimiters = num.scan(/[\D]/)

    case used_delimiters.uniq.length
    when 0
      major, minor = num, 0
    when 2
      thousands_separator, decimal_mark = used_delimiters.uniq

      major, minor = num.gsub(thousands_separator, '').split(decimal_mark)
      min = 0 unless min
    when 1
      decimal_mark = used_delimiters.first

      if decimal_char == decimal_mark
        major, minor = num.split(decimal_char)
      else
        if num.scan(decimal_mark).length > 1 # multiple matches; treat as decimal_mark
          major, minor = num.gsub(decimal_mark, ''), 0
        else
          possible_major, possible_minor = num.split(decimal_mark)
          possible_major ||= "0"
          possible_minor ||= "00"

          if possible_minor.length != 3 # thousands_separator
            major, minor = possible_major, possible_minor
          else
            if possible_major.length > 3
              major, minor = possible_major, possible_minor
            else
              if decimal_mark == '.'
                major, minor = possible_major, possible_minor
              else
                major, minor = "#{possible_major}#{possible_minor}", 0
              end
            end
          end
        end
      end
    else
      raise ArgumentError, "Invalid currency amount"
    end

    cents = major.to_i * currency.subunit_to_unit
    minor = minor.to_s
    minor = if minor.size < currency.decimal_places
              (minor + ("0" * currency.decimal_places))[0,currency.decimal_places].to_i
            elsif minor.size > currency.decimal_places
              if minor[currency.decimal_places,1].to_i >= 5
                minor[0,currency.decimal_places].to_i+1
              else
                minor[0,currency.decimal_places].to_i
              end
            else
              minor.to_i
            end

    cents += minor

    negative? ? cents * -1 : cents
  end

  def self.negative?
    NEGATIVE_NUMBER_RE === @original_number
  end

  def self.contains_hyphen?(num)
    if num.include?('-')
      raise ArgumentError, "Invalid currency amount (hyphen)"
    end
    num
  end

  def self.strip_negative_symbols(num)
    stripped_number = num.sub(NEGATIVE_NUMBER_RE, '')
    contains_hyphen?(stripped_number)
  end

end
