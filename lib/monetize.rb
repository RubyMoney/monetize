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

    def parse(input, currency = Money.default_currency, options = {})
      parse! input, currency, options
    rescue Error
      nil
    end

    def parse!(input, currency = Money.default_currency, options = {})
      return input if input.is_a?(Money)
      return from_numeric(input, currency) if input.is_a?(Numeric)

      parser = Monetize::Parser.new(input, currency, options)
      amount, currency = parser.parse

      Money.from_amount(amount, currency)
    rescue Money::Currency::UnknownCurrency => e
      fail ParseError, e.message
    end

    def parse_collection(input, currency = Money.default_currency, options = {})
      Collection.parse(input, currency, options)
    end

    def from_string(value, currency = Money.default_currency)
      value = BigDecimal(value.to_s)
      Money.from_amount(value, currency)
    end

    def from_fixnum(value, currency = Money.default_currency)
      Money.from_amount(value, currency)
    end
    alias_method :from_integer, :from_fixnum

    def from_float(value, currency = Money.default_currency)
      Money.from_amount(value, currency)
    end

    def from_bigdecimal(value, currency = Money.default_currency)
      Money.from_amount(value, currency)
    end

    def from_numeric(value, currency = Money.default_currency)
      fail ArgumentError, "'value' should be a type of Numeric" unless value.is_a?(Numeric)
      Money.from_amount(value, currency)
    end

    def extract_cents(input, currency = Money.default_currency)
      warn '[DEPRECATION] Monetize.extract_cents is deprecated. Use Monetize.parse().cents'

      money = parse(input, currency)
      money.cents if money
    end
  end
end
