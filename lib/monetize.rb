# encoding: utf-8

require 'money'
require 'monetize/core_extensions'
require 'monetize/errors'
require 'monetize/version'
require 'monetize/parser'
require 'monetize/collection'

module Monetize
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
    parse! input, currency, options
  rescue Error
    nil
  end

  def self.parse!(input, currency = Money.default_currency, options = {})
    return input if input.is_a?(Money)
    return from_numeric(input, currency) if input.is_a?(Numeric)

    parser = Monetize::Parser.new(input, currency, options)
    currency_from_input = Money::Currency.wrap(parser.parse_currency)

    Money.new(parser.parse_cents(currency_from_input), currency_from_input)
  rescue Money::Currency::UnknownCurrency => e
    fail ParseError, e.message
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
  singleton_class.send(:alias_method, :from_integer, :from_fixnum)

  def self.from_float(value, currency = Money.default_currency)
    value = BigDecimal.new(value.to_s)
    from_bigdecimal(value, currency)
  end

  def self.from_bigdecimal(value, currency = Money.default_currency)
    Money.from_amount(value, currency)
  end

  def self.from_numeric(value, currency = Money.default_currency)
    case value
    when Integer
      from_fixnum(value, currency)
    when Numeric
      value = BigDecimal.new(value.to_s)
      from_bigdecimal(value, currency)
    else
      fail ArgumentError, "'value' should be a type of Numeric"
    end
  end

  def self.extract_cents(input, currency = Money.default_currency)
    Monetize::Parser.new(input).parse_cents(currency)
  end
end
