require 'monetize/parser'
require 'monetize/tokenizer'

module Monetize
  class StrictParser
    # TODO: perform exhaustive match
    # TODO: error subclasses with detailed explanation
    # TODO: check if decimal mark is a thousands separator (1,000 USD)
    # TODO: switch to using allowed format as strings for added flexibility

    def initialize(input, fallback_currency = Money.default_currency, options = {})
      @input = input.to_s
      @options = options
      @fallback_currency = fallback_currency
    end

    def parse
      result = Tokenizer.new(input, options).process

      unless ALLOWED_FORMATS.include?(result.map(&:first))
        raise ParseError, "invalid input - #{result.map(&:first)}"
      end

      amount = result.find { |token| token.type == :amount }
      sign = result.find { |token| token.type == :sign }
      symbol = result.find { |token| token.type == :symbol }
      currency_iso = result.find { |token| token.type == :currency_iso }

      currency =
        if currency_iso
          parse_currency_iso(currency_iso.match.to_s)
        elsif symbol && assume_from_symbol?
          parse_symbol(symbol.match.to_s)
        else
          fallback_currency
        end

      amount = parse_amount(currency, amount.match, sign&.match)

      [amount, currency]
    end

    private

    ALLOWED_FORMATS = [
      [:amount],                                # 9.99
      [:sign, :amount],                         # -9.99
      [:symbol, :amount],                       # £9.99
      [:sign, :symbol, :amount],                # -£9.99
      [:symbol, :sign, :amount],                # £-9.99
      [:symbol, :amount, :sign],                # £9.99-
      [:amount, :symbol],                       # 9.99£
      [:sign, :amount, :symbol],                # -9.99£
      [:currency_iso, :amount],                 # GBP 9.99
      [:currency_iso, :sign, :amount],          # GBP -9.99
      [:amount, :currency_iso],                 # 9.99 GBP
      [:sign, :amount, :currency_iso],          # -9.99 GBP
      [:symbol, :amount, :currency_iso],        # £9.99 GBP
      [:sign, :symbol, :amount, :currency_iso], # -£9.99 GBP
    ].freeze

    attr_reader :input, :fallback_currency, :options

    def parse_amount(currency, amount, sign)
      multiplier = amount[:multiplier]
      amount = amount[:amount].gsub(' ', '')

      used_delimiters = amount.scan(/[^\d]/).uniq

      num =
        case used_delimiters.length
        when 0
          amount.to_f
        when 1
          decimal_mark = used_delimiters.first
          amount = amount.gsub(decimal_mark, '.')

          amount.to_f
        when 2
          thousands_separator, decimal_mark = used_delimiters
          amount = amount.gsub(thousands_separator, '')
          amount = amount.gsub(decimal_mark, '.')

          amount.to_f
        else
          raise ParseError, 'invalid amount of delimiters used'
        end

      num = apply_multiplier(num, multiplier)
      num = apply_sign(num, sign.to_s)

      num
    end

    def parse_symbol(symbol)
      Money::Currency.wrap(Monetize::Parser::CURRENCY_SYMBOLS[symbol])
    end

    def parse_currency_iso(currency_iso)
      Money::Currency.wrap(currency_iso)
    end

    def assume_from_symbol?
      options.fetch(:assume_from_symbol) { Monetize.assume_from_symbol }
    end

    def apply_multiplier(num, multiplier)
      return num unless multiplier

      exponent = Monetize::Parser::MULTIPLIER_SUFFIXES[multiplier.to_s.upcase]
      num * 10**exponent
    end

    def apply_sign(num, sign)
      sign == '-' ? num * -1 : num
    end
  end
end
