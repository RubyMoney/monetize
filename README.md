# Monetize

[![Gem Version](https://badge.fury.io/rb/monetize.png)](http://badge.fury.io/rb/monetize)
[![Build Status](https://travis-ci.org/RubyMoney/monetize.png?branch=master)](https://travis-ci.org/RubyMoney/monetize)
[![Code Climate](https://codeclimate.com/github/RubyMoney/monetize.png)](https://codeclimate.com/github/RubyMoney/monetize)
[![Coverage Status](https://coveralls.io/repos/RubyMoney/monetize/badge.png)](https://coveralls.io/r/RubyMoney/monetize)
[![Dependency Status](https://gemnasium.com/RubyMoney/monetize.png)](https://gemnasium.com/RubyMoney/monetize)
[![License](http://img.shields.io/license/MIT.png?color=green)](http://opensource.org/licenses/MIT)

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
Monetize.parse("$100") == Money.new(100_00, "USD")
Monetize.parse("€100") == Money.new(100_00, "EUR")
Monetize.parse("£100") == Money.new(100_00, "GBP")

"100".to_money == Money.new(100_00, "USD")
```

Optionally, enable the ability to assume the currency from a passed symbol.

```ruby
Monetize.assume_from_symbol = true

"$100".to_money == Money.new(100_00, "USD")
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
