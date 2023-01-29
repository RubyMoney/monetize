require 'monetize/parser'

module Monetize
  class Tokenizer
    SYMBOLS = Monetize::Parser::CURRENCY_SYMBOLS.keys.map { |symbol| Regexp.escape(symbol) }.freeze
    THOUSAND_SEPARATORS = /[\.\ ,]/.freeze
    DECIMAL_MARKS = /[\.,]/.freeze
    MULTIPLIERS = Monetize::Parser::MULTIPLIER_SUFFIXES.keys.join('|').freeze

    SYMBOL_REGEXP = Regexp.new(SYMBOLS.join('|')).freeze
    CURRENCY_ISO_REGEXP = /(?<![A-Z])[A-Z]{3}(?![A-Z])/i.freeze
    SIGN_REGEXP = /[\-\+]/.freeze
    AMOUNT_REGEXP = %r{
      (?<amount>                         # amount group
        \d+                              # starts with at least one digit
        (?:#{THOUSAND_SEPARATORS}\d{3})* # separated into groups of 3 digits by a thousands separator
        (?!\d)                           # not followed by a digit
        (?:#{DECIMAL_MARKS}\d+)?         # has decimal mark followed by decimal part
      )
      (?<multiplier>#{MULTIPLIERS})?     # optional multiplier
    }ix.freeze

    class Token < Struct.new(:type, :match); end

    def initialize(input, options = {})
      @original_input = input
      @options = options
    end

    def process
      # matches are removed from the input string to avoid overlapping matches
      input = original_input.dup
      result = []

      result += match(input, :currency_iso, CURRENCY_ISO_REGEXP)
      result += match(input, :symbol, SYMBOL_REGEXP)
      result += match(input, :sign, SIGN_REGEXP)
      result += match(input, :amount, AMOUNT_REGEXP)

      result.sort_by { |token| token.match.offset(0).first }
    end

    private

    attr_reader :original_input, :options

    def match(input, type, regexp)
      tokens = []
      input.scan(regexp) { tokens << Token.new(type, Regexp.last_match) }

      # Replace the matches from the input with § to avoid over-matching
      tokens.each do |token|
        offset = token.match.offset(0)
        input[offset.first..(offset.last - 1)] = '§' * token.match.to_s.length
      end

      tokens
    end

    def preview(result)
      preview_input = original_input.dup
      result.reverse.each do |token|
        offset = token.match.offset(0)
        preview_input.slice!(offset.first, token.match.to_s.length)
        preview_input.insert(offset.first, "<#{token.type}>")
      end

      puts preview_input
    end
  end
end
