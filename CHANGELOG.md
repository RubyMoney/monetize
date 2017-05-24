# Changelog

## 1.7.0
- Money version updated to 6.9
- Coveralls version update to 0.8.20
- Add South Korean Won currency
- Improve conversion to Money from Hash

## 1.6.0
- Ruby 2.4.0 support
- Money version updated to 6.8

## 1.5.0
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
- Required Forwardable on Collection to resolve NameError [\#44](https://github.com/RubyMoney/monetize/issues/44)
- Add capability to parse currency amounts given with suffixes (K, M, B, and T)

## 1.3.0
- Add NilClass extension
- Added correct parsing of Brazilian Real $R symbol
- Add testing task for  Brazilian Real parsing
- Add Lira Sign (₤) as a symbol for GBP

## 1.3.1
- Updated Money version dependency to 6.6

## master
- Fixed support for <code>Money.infinite_precision = true</code> in .to_money
- Add Rubocop config to project
- Reformat code to adapt to Rubocop guidelines
- Add config setting to always enforce currency delimiters
- Add rake console task
- Fix issue where parsing a Money object resulted in a Money object with its currency set to `Money.default_currency`,
  rather than the currency that it was sent in as.
- Add South Korean Won currency
