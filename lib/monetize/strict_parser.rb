require 'monetize/parser'
require 'monetize/tokenizer'

module Monetize
  class StrictParser < Parser
    # TODO: switch to using allowed format as strings for added flexibility

    THOUSAND_SEPARATORS = /[\.\ ,]/.freeze
    DECIMAL_MARKS = /[\.,]/.freeze

    # Some advanced regexp tips to understand the next bit of code:
    # "?:"       - makes the group non-capturing, excluding it from the resulting match data
    # "?<name>"  - creates a named capture
    # "\k<name>" - backreferences a named capture
    # "?!"       - negative lookahead (next character(-s) can't be the contents of this group)
    AMOUNT_REGEXP = %r{
      ^
        (?:                                         # whole units
          (?:                                       # try to capture units separated by thousands
            \d{1,3}                                 # must start with 3 or less whole numbers
            (?:(?<ts>#{THOUSAND_SEPARATORS})\d{3})? # first occurance of separated thousands, captures the separator
            (?:\k<ts>\d{3})*                        # other iterations with a the same exact separator
          )
          |\d+                                      # fallback to non thousands-separated units
        )
        (?:                                         # this group captures subunits
          (?!\k<ts>)                                # disallow captured thousands separator as decimals separator
          (?<ds>#{DECIMAL_MARKS})                   # captured decimal separator
          \d+                                       # subunits
        )?
      $
    }ix.freeze

    def initialize(input, fallback_currency = Money.default_currency, options = {})
      @input = input.to_s
      @options = options
      @fallback_currency = Money::Currency.wrap(fallback_currency)
      # This shouldn't be here, however String#to_money defaults currency to nil. Ideally we want
      # the default to always be Money.default_currency unless specified. In that case an explicit
      # nil would indicate that the currency must be determined from the input.
      @fallback_currency ||= Money.default_currency
    end

    def parse
      tokens = Tokenizer.new(input, options).process

      unless ALLOWED_FORMATS.include?(tokens.map(&:first))
        raise ParseError, "invalid input - #{tokens.map(&:first)}"
      end

      amount = tokens.find { |token| token.type == :amount }
      sign = tokens.find { |token| token.type == :sign }
      symbol = tokens.find { |token| token.type == :symbol }
      currency_iso = tokens.find { |token| token.type == :currency_iso }

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

    def parse_amount(currency, amount_match, sign)
      amount = amount_match[:amount]
      multiplier = amount_match[:multiplier]

      matches = amount.match(AMOUNT_REGEXP)

      unless matches
        raise ParseError, 'the provided input does not contain a valid amount'
      end

      thousands_separator = matches[:ts]
      decimal_separator = matches[:ds]

      # A single thousands separator without a decimal separator might be considered a decimal
      # separator in some cases (e.g. '1.001 TND' is likely 1.001 and not 1001). Here we need to
      # check if the currency allows 3+ subunits.
      if thousands_separator &&
          !decimal_separator &&
          currency.subunit_to_unit > 100 &&
          amount.count(thousands_separator) == 1
        _, possible_subunits = amount.split(thousands_separator)

        if possible_subunits.length > 2
          decimal_separator = thousands_separator
          thousands_separator = nil
        end
      end

      amount.gsub!(thousands_separator, '') if thousands_separator
      amount.gsub!(decimal_separator, '.') if decimal_separator
      amount = amount.to_f

      amount = apply_multiplier(amount, multiplier)
      amount = apply_sign(amount, sign.to_s)

      amount
    end

    def parse_symbol(symbol)
      Money::Currency.wrap(CURRENCY_SYMBOLS[symbol])
    end

    def parse_currency_iso(currency_iso)
      Money::Currency.wrap(currency_iso)
    end

    def assume_from_symbol?
      options.fetch(:assume_from_symbol) { Monetize.assume_from_symbol }
    end

    def apply_multiplier(num, multiplier)
      return num unless multiplier

      exponent = MULTIPLIER_SUFFIXES[multiplier.to_s.upcase]
      num * 10**exponent
    end

    def apply_sign(num, sign)
      sign == '-' ? num * -1 : num
    end
  end
end
