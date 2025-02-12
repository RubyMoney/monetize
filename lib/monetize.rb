# encoding: utf-8

require 'money'
require 'monetize/core_extensions'
require 'monetize/errors'
require 'monetize/version'
require 'monetize/optimistic_parser'
require 'monetize/strict_parser'
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


    # Where this set to true, the behavior for parsing thousands separators is changed to 
    # expect that eg. €10.000 is EUR 10 000 and not EUR 10.000 - it's incredibly rare when parsing 
    # human text that we're dealing with fractions of cents.
    attr_accessor :expect_whole_subunits

    # Specify which of the previously registered parsers should be used when parsing an input
    # unless overriden using the :parser keyword option for the .parse and parse! methods.
    attr_accessor :default_parser

    def parse(input, currency = Money.default_currency, options = {})
      parse! input, currency, options
    rescue Error
      nil
    end

    def parse!(input, currency = Money.default_currency, options = {})
      return input if input.is_a?(Money)
      return from_numeric(input, currency) if input.is_a?(Numeric)

      parser = fetch_parser(input, currency, options)
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

    # Registers a new parser class along with the default options. It can then be used by
    # providing a :parser option when parsing an input or by specifying a default parser
    # using Monetize.default_parser=.
    def register_parser(name, klass, options = {})
      @parsers ||= {}
      @parsers[name] = [klass, options]
    end

    private

    attr_reader :parsers

    def fetch_parser(input, currency, options)
      parser_name = options[:parser] || default_parser
      parser_klass, parser_options = parsers.fetch(parser_name) do
        raise ArgumentError, "Parser not registered: #{parser_name}"
      end
      parser_klass.new(input, currency, parser_options.merge(options))
    end
  end
end

Monetize.register_parser(:optimistic, Monetize::OptimisticParser)
Monetize.register_parser(:strict, Monetize::StrictParser)
Monetize.default_parser = :optimistic
