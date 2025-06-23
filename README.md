⚠️ **Maintainer(s) Wanted — RubyMoney Needs New Stewardship**  

Hi! I’m the current (and only) active maintainer, and I no longer have the capacity to look after this project—or any other gems under the **RubyMoney** GitHub organization.  

**What we’re looking for:** An individual or team willing to take ownership of *the entire organization* (all gems, docs, CI, and Rubygems ownership).  

**Timeline**  

| Date | Action |
|------|--------|
| **Now → 30 Sep 2025** | Open an issue titled “Maintainer application” (or email `shane@emmons.io`) and tell us who you are, why you care, and your plan for the libraries. |
| **1 Oct 2025** | If no successor is confirmed, every repository in RubyMoney will be **archived (read-only)**. No new issues, PRs, or releases will be possible after that point. |

Security-critical patches will still be merged during the transition window, but no new features will be accepted.  

— Shane Emmons (current steward) • June 23 2025

# Monetize

[![Gem Version](https://badge.fury.io/rb/monetize.svg)](http://badge.fury.io/rb/monetize)
[![Ruby](https://github.com/RubyMoney/monetize/actions/workflows/ruby.yml/badge.svg)](https://github.com/RubyMoney/monetize/actions/workflows/ruby.yml)
[![Maintainability](https://api.codeclimate.com/v1/badges/a2cf7b7a170b4ca68fe8/maintainability)](https://codeclimate.com/github/RubyMoney/monetize/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/a2cf7b7a170b4ca68fe8/test_coverage)](https://codeclimate.com/github/RubyMoney/monetize/test_coverage)
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
