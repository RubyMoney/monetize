# encoding: utf-8

require 'monetize'
require 'forwardable'

module Monetize
  class Collection
    extend Forwardable
    include Enumerable
    def_delegators :@list, :[], :each, :last

    attr_reader :input, :currency, :options

    def self.parse(input, currency = Money.default_currency, options = {})
      new(input, currency, options).parse
    end

    def initialize(input, currency = Money.default_currency, options = {})
      if input.respond_to? :strip
        @input = input.clone.strip
      else
        raise ArgumentError 'Input must be a string'
      end

      @currency = currency
      @options = options
      @list = []
    end

    def parse
      if range?
        @list = split_range.map { |fragment| Monetize.parse(fragment, currency, options) }
      else
        @list = split_list.map { |fragment| Monetize.parse(fragment, currency, options) }
      end

      self
    end

    def range?
      RANGE_SPLIT =~ input
    end

    private

    LIST_SPLIT = %r{[/,]}
    RANGE_SPLIT = /-/

    def split_list
      Array @input.split(LIST_SPLIT)
        .map(&:strip)
    end

    def split_range
      Array @input.split(RANGE_SPLIT)
        .map(&:strip)
    end
  end
end
