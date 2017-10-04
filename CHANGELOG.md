# Changelog

## 1.7.0
- Add South Korean Won currency
- Money version updated to 6.9
- Coveralls version update to 0.8.20
- Add South Korean Won currency
- Improve conversion to Money from Hash

## 1.6.0
- Ruby 2.4.0 support
- Money version updated to 6.8

## 1.5.0
- Fix issue where parsing a Money object resulted in a Money object with its currency set to `Money.default_currency`,
  rather than the currency that it was sent in as.
- Add extra currencies:
  - Azerbaijani manat
  - Chinese yuan
  - Czech koruna
  - Hungarian forint
  - Indinan rupee
  - Russian ruble
  - Turkish Lira
  - Ukrainian Hryvnia
  - Swiss Frank
  - Polish Zloty
  - Kazakhstani Tenge
- Parsing a Money object returns it unchanged
- Fix issue with loosing precision on BigDecimal input
- Add Swedish krona
- Exclud ambiguous kr symbol from parsing
- Fix JPY parsing
- Sublcass all errors to Monetize::Error
- Fix ruby 1.9.3 compatibility
- Suppress errors when using parse. Use `parse!` instead
- Strip currency symbol prefix when parsing input

## 1.4.0
- Fixed support for <code>Money.infinite_precision = true</code> in .to_money
- Add Rubocop config to project
- Reformat code to adapt to Rubocop guidelines
- Add config setting to always enforce currency delimiters
- Add rake console task
- Required Forwardable on Collection to resolve NameError [\#44](https://github.com/RubyMoney/monetize/issues/44)
- Add capability to parse currency amounts given with suffixes (K, M, B, and T)

## 1.3.1
- Updated Money version dependency to 6.6

## 1.3.0
- Add Lira Sign (₤) as a symbol for GBP

## 1.2.0
- Add support for parsing Yen symbol
- Add `Monetize.parse_collection` and `Monetize::Collection` class for parsing multiple values
- Add parsing of C$ for Canadian Dollar
- Add NilClass extension
- Add Hash extension

## 1.1.0
- Add :assume_from_symbol option to #parse
- Enable #parse to detect currency with signed amounts
- Updated Money version dependency to 6.5.0

## 1.0.0
- Updated Money version dependency to 6.4.0

## 0.4.1
- Updated Money version dependency to 6.2.1

## 0.4.0
- Added correct parsing of Brazilian Real $R symbol
- Add testing task for  Brazilian Real parsing
- Updated Money version dependency to 6.2.0
