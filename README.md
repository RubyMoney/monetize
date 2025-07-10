# Monetize

[![Gem Version](https://badge.fury.io/rb/monetize.svg)](http://badge.fury.io/rb/monetize)
[![Ruby](https://github.com/RubyMoney/monetize/actions/workflows/ruby.yml/badge.svg)](https://github.com/RubyMoney/monetize/actions/workflows/ruby.yml)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](http://opensource.org/licenses/MIT)

A library for converting various objects into `Money` objects.

## Installation

Run:

    bundle add monetize

Or install it yourself as:

    $ gem install monetize

## Usage

```ruby
Monetize.parse("USD 100") == Money.new(100_00, "USD")
Monetize.parse("EUR 100") == Money.new(100_00, "EUR")
Monetize.parse("GBP 100") == Money.new(100_00, "GBP")

"100".to_money == Money.new(100_00, "USD")
```

Optionally, enable the ability to assume the currency from a passed symbol. Otherwise, currency symbols will be ignored, and USD used as the default currency:

```ruby
Monetize.parse("£100") == Money.new(100_00, "USD")

Monetize.assume_from_symbol = true

Monetize.parse("£100") == Money.new(100_00, "GBP")
"€100".to_money == Money.new(100_00, "EUR")
```

Parsing can be improved where the input is not expected to contain fractional subunits.
To do this, set `Monetize.expect_whole_subunits = true`

```ruby
Monetize.parse('EUR 10,000') == Money.new(100_00, "EUR")

Monetize.expect_whole_subunits = true
Monetize.parse('EUR 10,000') == Money.new(10_000_00, "EUR")
```

Why does this work?  If we expect fractional subunits then the parser will treat a single
delimiter as a decimal marker if it matches the currency's decimal marker.  But often
this is not the case - a European site will show $10.000 because that's the local format.
As a human, if this was a stock ticker we might expect fractional cents.  If it's a retail price we know it's actually an incorrect thousands separator.


Monetize can also parse a list of values, returning an array-like object ([Monetize::Collection](lib/collection.rb)):

```ruby
Monetize.parse_collection("€80/$100") == [Money.new(80_00, "EUR"), Money.new(100_00, "USD")]
Monetize.parse_collection("€80, $100") == [Money.new(80_00, "EUR"), Money.new(100_00, "USD")]

# The #range? method detects the presence of a hyphen
Monetize.parse_collection("€80-$100").range? == true
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.
