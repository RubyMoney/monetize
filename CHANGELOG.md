# Changelog

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
