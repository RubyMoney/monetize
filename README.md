# Monetize

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
Money.parse("$100") == Money.new(100_00, "USD")
Money.parse("€100") == Money.new(100_00, "EUR")
Money.parse("£100") == Money.new(100_00, "GBP")

"$100".to_money == Money.new(100_00, "USD")
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
