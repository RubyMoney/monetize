# Monetize

[![Gem Version](https://badge.fury.io/rb/monetize.svg)](http://badge.fury.io/rb/monetize)
[![Build Status](https://travis-ci.org/RubyMoney/monetize.svg?branch=master)](https://travis-ci.org/RubyMoney/monetize)
[![Code Climate](https://codeclimate.com/github/RubyMoney/monetize.svg)](https://codeclimate.com/github/RubyMoney/monetize)
[![Coverage Status](https://coveralls.io/repos/RubyMoney/monetize/badge.svg)](https://coveralls.io/r/RubyMoney/monetize)
[![Dependency Status](https://gemnasium.com/RubyMoney/monetize.svg)](https://gemnasium.com/RubyMoney/monetize)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](http://opensource.org/licenses/MIT)

A library for converting various objects into `Money` objects.

## Installation

Add this line to your application's Gemfile:

    gem 'monetize'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install monetize

## Usage

```ruby
Monetize.parse("USD 100") == Money.new(100_00, "USD")
Monetize.parse("EUR 100") == Money.new(100_00, "EUR")
Monetize.parse("GBP 100") == Money.new(100_00, "GBP")

"100".to_money == Money.new(100_00, "USD")
```

`parse` will return `nil` if it is unable to parse the input. Use `parse!` instead if you want a `Monetize::Error` (or one of the subclasses) to be raised instead:

```ruby
>> Monetize.parse('OMG 100')
=> nil

>> Monetize.parse!('OMG 100')
Monetize::ParseError: Unknown currency 'omg'
```

Optionally, enable the ability to assume the currency from a passed symbol. Otherwise, currency symbols will be ignored, and USD used as the default currency:

```ruby
Monetize.parse("£100") == Money.new(100_00, "USD")

Monetize.assume_from_symbol = true

Monetize.parse("£100") == Money.new(100_00, "GBP")
"€100".to_money == Money.new(100_00, "EUR")
```

Monetize can also parse a list of values, returning an array-like object ([Monetize::Collection](lib/collection.rb)):

```ruby
Monetize.parse_collection("€80/$100") == [Money.new(80_00, "EUR"), Money.new(100_00, "USD")]
Monetize.parse_collection("€80, $100") == [Money.new(80_00, "EUR"), Money.new(100_00, "USD")]

# The #range? method detects the presence of a hyphen
Monetize.parse_collection("€80-$100").range? == true
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.
