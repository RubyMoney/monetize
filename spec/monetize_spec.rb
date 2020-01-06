# encoding: utf-8

require 'spec_helper'
require 'monetize'

describe Monetize do
  bar = <<-JSON
    {
      "priority": 1,
      "iso_code": "BAR",
      "iso_numeric": "840",
      "name": "Dollar with 4 decimal places",
      "symbol": "$",
      "subunit": "Cent",
      "subunit_to_unit": 10000,
      "symbol_first": true,
      "html_entity": "$",
      "decimal_mark": ".",
      "thousands_separator": ","
    }
  JSON

  eu4 = <<-JSON
    {
      "priority": 1,
      "iso_code": "EU4",
      "iso_numeric": "841",
      "name": "Euro with 4 decimal places",
      "symbol": "€",
      "subunit": "Cent",
      "subunit_to_unit": 10000,
      "symbol_first": true,
      "html_entity": "€",
      "decimal_mark": ",",
      "thousands_separator": "."
    }
  JSON

  describe '.parse' do
    it 'parses european-formatted inputs under 10EUR' do
      expect(Monetize.parse('EUR 5,95')).to eq Money.new(595, 'EUR')
    end

    it 'parses european-formatted inputs with multiple thousands-seperators' do
      expect(Monetize.parse('EUR 1.234.567,89')).to eq Money.new(1_234_567_89, 'EUR')
      expect(Monetize.parse('EUR 1.111.234.567,89')).to eq Money.new(1_111_234_567_89, 'EUR')
    end

    describe 'currency detection' do
      context 'opted in' do
        before :all do
          Monetize.assume_from_symbol = true
        end

        after :all do
          Monetize.assume_from_symbol = false
        end

        Monetize::Parser::CURRENCY_SYMBOLS.each_pair do |symbol, iso_code|
          context iso_code do
            let(:currency) { Money::Currency.find(iso_code) }
            let(:amount) { 5_95 }
            let(:amount_in_units) { amount.to_f / currency.subunit_to_unit }

            it 'ensures correct amount calculations for test' do
              expect(amount_in_units * currency.subunit_to_unit).to eq(amount)
            end

            it "parses formatted inputs with #{iso_code} passed as a symbol" do
              expect(Monetize.parse("#{symbol}#{amount_in_units}")).to eq Money.new(amount, iso_code)
            end

            it "parses formatted inputs with #{iso_code} symbol is after the amount" do
              expect(Monetize.parse("#{amount_in_units}#{symbol}")).to eq Money.new(amount, iso_code)
            end

            context 'prefix' do
              it 'parses formatted inputs with plus sign and currency as a symbol' do
                expect(Monetize.parse("+#{symbol}#{amount_in_units}")).to eq Money.new(amount, iso_code)
              end

              it 'parses formatted inputs with minus sign and currency as a symbol' do
                expect(Monetize.parse("-#{symbol}#{amount_in_units}")).to eq Money.new(-amount, iso_code)
              end
            end

            context 'postfix' do
              it 'parses formatted inputs with currency symbol and postfix minus sign' do
                expect(Monetize.parse("#{symbol}#{amount_in_units}-")).to eq Money.new(-amount, iso_code)
              end

              it 'parses formatted inputs with currency symbol and postfix plus sign' do
                expect(Monetize.parse("#{symbol}#{amount_in_units}+")).to eq Money.new(amount, iso_code)
              end
            end

            context 'amount suffixes' do
              it 'parses formatted inputs with amounts given with suffixes' do
                expect(Monetize.parse("#{symbol}1.26K")).to eq Money.new(1_260 * currency.subunit_to_unit, iso_code)
                expect(Monetize.parse("#{symbol}126.36M")).to eq Money.new(126_360_000 * currency.subunit_to_unit, iso_code)
                expect(Monetize.parse("#{symbol}.45B")).to eq Money.new(450_000_000 * currency.subunit_to_unit, iso_code)
                expect(Monetize.parse("-#{symbol}2.45B")).to eq Money.new(-2_450_000_000 * currency.subunit_to_unit, iso_code)
                expect(Monetize.parse("#{symbol}1.65T")).to eq Money.new(1_650_000_000_000 * currency.subunit_to_unit, iso_code)
              end
            end

            it 'parses formatted inputs with symbol and surrounding spaces' do
              expect(Monetize.parse(" #{symbol}#{amount_in_units} ")).to eq Money.new(amount, iso_code)
            end

            it 'parses formatted inputs without currency detection when overridden' do
              expect(Monetize.parse("#{symbol}5.95", nil, assume_from_symbol: false)).to eq Money.new(amount, 'USD')
            end
          end
        end

        it 'should assume default currency if not a recognised symbol' do
          expect(Monetize.parse('L9.99')).to eq Money.new(999, 'USD')
        end

        it 'ignores ZAR symbols that is part of a text' do
          expect(Monetize.parse('EUR 9.99')).to eq Money.new(999, 'EUR')
          expect(Monetize.parse('9.99 EUR')).to eq Money.new(999, 'EUR')
        end

        context 'negatives' do
          it 'ignores the ambiguous kr symbol' do
            # Could mean either of DKK, EEK, ISK, NOK, SEK
            expect(Monetize.parse('kr9.99')).to eq Money.new(999, 'USD')
          end
        end
      end

      context 'opted out' do
        before do
          Monetize.assume_from_symbol = false
        end

        it 'ignores the Euro symbol' do
          expect(Monetize.parse('€5.95')).to eq Money.new(595, 'USD')
        end

        it 'ignores the South African Rand symbol' do
          expect(Monetize.parse('R5.95')).to eq Money.new(595, 'USD')
        end

        it 'ignores the Euro symbol with surrounding spaces' do
          expect(Monetize.parse(' €5.95 ')).to eq Money.new(595, 'USD')
        end

        it 'ignores the British Pounds Sterling symbol' do
          expect(Monetize.parse('£9.99')).to eq Money.new(999, 'USD')
        end

        it 'parses formatted inputs with currency detection when overridden' do
          expect(Monetize.parse('£9.99', nil, assume_from_symbol: true)).to eq Money.new(999, 'GBP')
        end
      end

      it 'should opt out by default' do
        expect(Monetize.assume_from_symbol).to be_falsy
      end

      context 'ISO code' do
        it 'parses currency given as ISO code' do
          expect('20.00 USD'.to_money).to eq Money.new(20_00, 'USD')
          expect('20.00 EUR'.to_money).to eq Money.new(20_00, 'EUR')
          expect('20.00 GBP'.to_money).to eq Money.new(20_00, 'GBP')
        end

        it 'raises an error if currency code is invalid' do
          expect { '20.00 OMG'.to_money }.to raise_error Monetize::ParseError
        end
      end
    end

    it 'parses USD-formatted inputs under $10' do
      five_ninety_five = Money.new(595, 'USD')

      expect(Monetize.parse(5.95)).to eq five_ninety_five
      expect(Monetize.parse('5.95')).to eq five_ninety_five
      expect(Monetize.parse('$5.95')).to eq five_ninety_five
      expect(Monetize.parse("\n $5.95 \n")).to eq five_ninety_five
      expect(Monetize.parse('$ 5.95')).to eq five_ninety_five
      expect(Monetize.parse('$5.95 ea.')).to eq five_ninety_five
      expect(Monetize.parse('$5.95, each')).to eq five_ninety_five
    end

    it 'parses USD-formatted inputs with multiple thousands-seperators' do
      expect(Monetize.parse('1,234,567.89')).to eq Money.new(1_234_567_89, 'USD')
      expect(Monetize.parse('1,111,234,567.89')).to eq Money.new(1_111_234_567_89, 'USD')
    end

    it 'parses DKK-formatted inputs' do
      expect(Monetize.parse('kr.123,45', 'DKK')).to eq Money.new(123_45, 'DKK')
      expect(Monetize.parse('kr.123.45', 'DKK')).to eq Money.new(123_45, 'DKK')
      expect(Monetize.parse('kr.45k', 'DKK')).to eq Money.new(45_000_00, 'DKK')
    end

    it 'returns nil if input is a price range' do
      expect(Monetize.parse('$5.95-10.95')).to be_nil
      expect(Monetize.parse('$5.95 - 10.95')).to be_nil
      expect(Monetize.parse('$5.95 - $10.95')).to be_nil
    end

    it 'does not return a price for completely invalid input' do
      expect(Monetize.parse(nil)).to eq Money.empty
      expect(Monetize.parse('hellothere')).to eq Money.empty
      expect(Monetize.parse('')).to eq Money.empty
    end

    it 'handles negative inputs' do
      five_ninety_five = Money.new(-595, 'USD')

      expect(Monetize.parse('$-5.95')).to eq five_ninety_five
      expect(Monetize.parse('-$5.95')).to eq five_ninety_five
      expect(Monetize.parse('$5.95-')).to eq five_ninety_five
    end

    it 'returns nil when unable to detect polarity' do
      expect(Monetize.parse('-$5.95-')).to be_nil
    end

    it 'returns nil when more than 2 digit separators are used' do
      expect(Monetize.parse("123.34,56'89 EUR")).to be_nil
    end

    it 'parses correctly strings with repeated digit separator' do
      expect(Monetize.parse('19.12.89', 'EUR')).to eq Money.new(191_289_00, 'EUR')
    end

    it 'parses correctly strings with exactly 3 decimal digits' do
      expect(Monetize.parse('6,534', 'EUR')).to eq Money.new(653, 'EUR')
      expect(Monetize.parse('6.534', 'EUR')).to eq Money.new(653, 'EUR')

      Monetize.enforce_currency_delimiters = true
      expect(Monetize.parse('6.534', 'EUR')).to eq Money.new(6_534_00, 'EUR')
      Monetize.enforce_currency_delimiters = false
    end

    context 'Money object attempting to be parsed' do
      let(:money) { Money.new(595, 'GBP') }

      it 'returns the original Money object' do
        expect(Monetize.parse(money)).to eq money
        expect(Monetize.parse(money).currency).to eq 'GBP'
        expect(Monetize.parse(money).cents).to eq 595
      end
    end

    context 'parsing an instance of Numeric class' do
      let(:integer)     { 10 }
      let(:float)       { 10.0 }
      let(:big_decimal) { BigDecimal('10') }

      [:integer, :float, :big_decimal].each do |type|
        it "returns a new Money object based on the #{type} input" do
          money = Monetize.parse(send(type), 'USD')

          expect(money).to be_instance_of(Money)
          expect(money.currency).to eq('USD')
          expect(money.cents).to eq(10_00)
        end
      end
    end

    context 'custom currencies with 4 decimal places' do
      before :each do
        Money::Currency.register(JSON.parse(bar, symbolize_names: true))
        Money::Currency.register(JSON.parse(eu4, symbolize_names: true))
      end

      after :each do
        Money::Currency.unregister(JSON.parse(bar, symbolize_names: true))
        Money::Currency.unregister(JSON.parse(eu4, symbolize_names: true))
      end

      # String#to_money(Currency) is equivalent to Monetize.parse(String, Currency)
      it 'parses strings respecting subunit to unit, decimal and thousands separator' do
        expect('$0.4'.to_money('BAR')).to eq Money.new(4000, 'BAR')
        expect('€0,4'.to_money('EU4')).to eq Money.new(4000, 'EU4')

        expect('$0.04'.to_money('BAR')).to eq Money.new(400, 'BAR')
        expect('€0,04'.to_money('EU4')).to eq Money.new(400, 'EU4')

        expect('$0.004'.to_money('BAR')).to eq Money.new(40, 'BAR')
        expect('€0,004'.to_money('EU4')).to eq Money.new(40, 'EU4')

        expect('$0.0004'.to_money('BAR')).to eq Money.new(4, 'BAR')
        expect('€0,0004'.to_money('EU4')).to eq Money.new(4, 'EU4')

        expect('$0.0024'.to_money('BAR')).to eq Money.new(24, 'BAR')
        expect('€0,0024'.to_money('EU4')).to eq Money.new(24, 'EU4')

        expect('$0.0324'.to_money('BAR')).to eq Money.new(324, 'BAR')
        expect('€0,0324'.to_money('EU4')).to eq Money.new(324, 'EU4')

        expect('$0.5324'.to_money('BAR')).to eq Money.new(5324, 'BAR')
        expect('€0,5324'.to_money('EU4')).to eq Money.new(5324, 'EU4')

        # Following currencies consider 4 decimal places
        # rubocop:disable Style/NumericLiterals
        expect('$6.5324'.to_money('BAR')).to eq Money.new(6_5324, 'BAR')
        expect('€6,5324'.to_money('EU4')).to eq Money.new(6_5324, 'EU4')

        expect('$86.5324'.to_money('BAR')).to eq Money.new(86_5324, 'BAR')
        expect('€86,5324'.to_money('EU4')).to eq Money.new(86_5324, 'EU4')

        expect('$186.5324'.to_money('BAR')).to eq Money.new(186_5324, 'BAR')
        expect('€186,5324'.to_money('EU4')).to eq Money.new(186_5324, 'EU4')

        expect('$3,331.0034'.to_money('BAR')).to eq Money.new(3_331_0034, 'BAR')
        expect('€3.331,0034'.to_money('EU4')).to eq Money.new(3_331_0034, 'EU4')

        expect('$8,883,331.0034'.to_money('BAR')).to eq Money.new(8_883_331_0034, 'BAR')
        expect('€8.883.331,0034'.to_money('EU4')).to eq Money.new(8_883_331_0034, 'EU4')
        # rubocop:enable Style/NumericLiterals
      end
    end
  end

  describe '.parse!' do
    it 'does not return a price if there is a price range' do
      expect { Monetize.parse!('$5.95-10.95') }.to raise_error Monetize::ParseError
      expect { Monetize.parse!('$5.95 - 10.95') }.to raise_error Monetize::ParseError
      expect { Monetize.parse!('$5.95 - $10.95') }.to raise_error Monetize::ParseError
    end

    it 'raises ArgumentError when unable to detect polarity' do
      expect { Monetize.parse!('-$5.95-') }.to raise_error Monetize::ParseError
    end
  end

  describe '.parse_collection' do
    it 'parses into a Money::Collection' do
      expect(Monetize.parse_collection('$7')).to be_a Monetize::Collection
    end

    it 'parses comma separated values' do
      collection = Monetize.parse_collection('$5, $7')
      expect(collection.first).to eq Monetize.parse('$5')
      expect(collection.last).to eq Monetize.parse('$7')
    end

    it 'parses slash separated values' do
      collection = Monetize.parse_collection('£4.50/€6')
      expect(collection.first).to eq Monetize.parse('£4.50')
      expect(collection.last).to eq Monetize.parse('€6')
    end

    it 'parses hyphens as ranges' do
      collection = Monetize.parse_collection('$4 - $10')
      expect(collection.first).to eq Monetize.parse('$4')
      expect(collection.last).to eq Monetize.parse('$10')
    end

    it 'raises an error if argument is invalid' do
      expect { Monetize.parse_collection(nil) }.to raise_error Monetize::ArgumentError
    end
  end

  describe '.from_string' do
    it 'converts given amount to cents' do
      expect(Monetize.from_string('1')).to eq Money.new(1_00)
      expect(Monetize.from_string('1')).to eq Money.new(1_00, 'USD')
      expect(Monetize.from_string('1', 'EUR')).to eq Money.new(1_00, 'EUR')
    end

    it 'respects :subunit_to_unit currency property' do
      expect(Monetize.from_string('1', 'USD')).to eq Money.new(1_00, 'USD')
      expect(Monetize.from_string('1', 'TND')).to eq Money.new(1_000, 'TND')
      expect(Monetize.from_string('1', 'JPY')).to eq Money.new(1, 'JPY')
    end

    it 'accepts a currency options' do
      m = Monetize.from_string('1')
      expect(m.currency).to eq Money.default_currency

      m = Monetize.from_string('1', Money::Currency.wrap('EUR'))
      expect(m.currency).to eq Money::Currency.wrap('EUR')

      m = Monetize.from_string('1', 'EUR')
      expect(m.currency).to eq Money::Currency.wrap('EUR')
    end
  end

  describe '.from_fixnum' do
    it 'converts given amount to cents' do
      expect(Monetize.from_fixnum(1)).to eq Money.new(1_00)
      expect(Monetize.from_fixnum(1)).to eq Money.new(1_00, 'USD')
      expect(Monetize.from_fixnum(1, 'EUR')).to eq Money.new(1_00, 'EUR')
    end

    it 'should respect :subunit_to_unit currency property' do
      expect(Monetize.from_fixnum(1, 'USD')).to eq Money.new(1_00, 'USD')
      expect(Monetize.from_fixnum(1, 'TND')).to eq Money.new(1_000, 'TND')
      expect(Monetize.from_fixnum(1, 'JPY')).to eq Money.new(1, 'JPY')
    end

    it 'accepts a currency options' do
      m = Monetize.from_fixnum(1)
      expect(m.currency).to eq Money.default_currency

      m = Monetize.from_fixnum(1, Money::Currency.wrap('EUR'))
      expect(m.currency).to eq Money::Currency.wrap('EUR')

      m = Monetize.from_fixnum(1, 'EUR')
      expect(m.currency).to eq Money::Currency.wrap('EUR')
    end

    it 'is aliased as from_integer' do
      expect(Monetize.from_integer(1)).to eq(Monetize.from_fixnum(1))
    end
  end

  describe '.from_float' do
    it 'converts given amount to cents' do
      expect(Monetize.from_float(1.2)).to eq Money.new(1_20)
      expect(Monetize.from_float(1.2)).to eq Money.new(1_20, 'USD')
      expect(Monetize.from_float(1.2, 'EUR')).to eq Money.new(1_20, 'EUR')
    end

    it 'respects :subunit_to_unit currency property' do
      expect(Monetize.from_float(1.2, 'USD')).to eq Money.new(1_20, 'USD')
      expect(Monetize.from_float(1.2, 'TND')).to eq Money.new(1_200, 'TND')
      expect(Monetize.from_float(1.2, 'JPY')).to eq Money.new(1, 'JPY')
    end

    it 'accepts a currency options' do
      m = Monetize.from_float(1.2)
      expect(m.currency).to eq Money.default_currency

      m = Monetize.from_float(1.2, Money::Currency.wrap('EUR'))
      expect(m.currency).to eq Money::Currency.wrap('EUR')

      m = Monetize.from_float(1.2, 'EUR')
      expect(m.currency).to eq Money::Currency.wrap('EUR')
    end
  end

  describe '.from_bigdecimal' do
    it 'converts given amount to cents' do
      expect(Monetize.from_bigdecimal(BigDecimal('1'))).to eq Money.new(1_00)
      expect(Monetize.from_bigdecimal(BigDecimal('1'))).to eq Money.new(1_00, 'USD')
      expect(Monetize.from_bigdecimal(BigDecimal('1'), 'EUR')).to eq Money.new(1_00, 'EUR')
    end

    it 'respects :subunit_to_unit currency property' do
      expect(Monetize.from_bigdecimal(BigDecimal('1'), 'USD')).to eq Money.new(1_00, 'USD')
      expect(Monetize.from_bigdecimal(BigDecimal('1'), 'TND')).to eq Money.new(1_000, 'TND')
      expect(Monetize.from_bigdecimal(BigDecimal('1'), 'JPY')).to eq Money.new(1, 'JPY')
    end

    it 'respects rounding mode when rounding amount to the nearest cent' do
      amount = BigDecimal('1.005')

      expect(Monetize.from_bigdecimal(amount, 'USD')).to eq Money.from_amount(amount, 'USD')
    end

    it 'accepts a currency options' do
      m = Monetize.from_bigdecimal(BigDecimal('1'))
      expect(m.currency).to eq Money.default_currency

      m = Monetize.from_bigdecimal(BigDecimal('1'), Money::Currency.wrap('EUR'))
      expect(m.currency).to eq Money::Currency.wrap('EUR')

      m = Monetize.from_bigdecimal(BigDecimal('1'), 'EUR')
      expect(m.currency).to eq Money::Currency.wrap('EUR')
    end

    context 'infinite_precision = true' do
      before do
        Money.infinite_precision = true
      end

      after do
        Money.infinite_precision = false
      end

      it 'keeps precision' do
        expect(Monetize.from_bigdecimal(BigDecimal('1'))).to eq Money.new(100)
        expect(Monetize.from_bigdecimal(BigDecimal('1.23456'))).to eq Money.new(123.456)
        expect(Monetize.from_bigdecimal(BigDecimal('-1.23456'))).to eq Money.new(-123.456)
        expect(Monetize.from_bigdecimal(BigDecimal('1.23456'))).to eq Money.new(123.456, 'USD')
        expect(Monetize.from_bigdecimal(BigDecimal('1.23456'), 'EUR')).to eq Money.new(123.456, 'EUR')

        expect('1'.to_money).to eq Money.new(100)
        expect('1.23456'.to_money).to eq Money.new(123.456)
        expect('-1.23456'.to_money).to eq Money.new(-123.456)
        expect('$1.23456'.to_money).to eq Money.new(123.456, 'USD')
        expect('1.23456 EUR'.to_money).to eq Money.new(123.456, 'EUR')
      end
    end
  end

  describe '.from_numeric' do
    it 'converts given amount to cents' do
      expect(Monetize.from_numeric(1)).to eq Money.new(1_00)
      expect(Monetize.from_numeric(1.0)).to eq Money.new(1_00)
      expect(Monetize.from_numeric(BigDecimal('1'))).to eq Money.new(1_00)
    end

    it 'raises ArgumentError with unsupported argument' do
      expect { Monetize.from_numeric('100') }.to raise_error(Monetize::ArgumentError)
    end

    it 'respects :subunit_to_unit currency property' do
      expect(Monetize.from_numeric(1, 'USD')).to eq Money.new(1_00, 'USD')
      expect(Monetize.from_numeric(1, 'TND')).to eq Money.new(1_000, 'TND')
      expect(Monetize.from_numeric(1, 'JPY')).to eq Money.new(1, 'JPY')
    end

    it 'accepts a bank option' do
      expect(Monetize.from_numeric(1)).to eq Money.new(1_00)
      expect(Monetize.from_numeric(1)).to eq Money.new(1_00, 'USD')
      expect(Monetize.from_numeric(1, 'EUR')).to eq Money.new(1_00, 'EUR')
    end

    it 'accepts a currency options' do
      m = Monetize.from_numeric(1)
      expect(m.currency).to eq Money.default_currency

      m = Monetize.from_numeric(1, Money::Currency.wrap('EUR'))
      expect(m.currency).to eq Money::Currency.wrap('EUR')

      m = Monetize.from_numeric(1, 'EUR')
      expect(m.currency).to eq Money::Currency.wrap('EUR')
    end
  end

  describe '.extract_cents' do
    it 'is deprecated' do
      allow(Monetize).to receive(:warn)

      Monetize.extract_cents('100')

      expect(Monetize)
        .to have_received(:warn)
        .with('[DEPRECATION] Monetize.extract_cents is deprecated. Use Monetize.parse().cents')
    end

    it 'extracts cents from a given string' do
      expect(Monetize.extract_cents('10.99')).to eq(1099)
    end

    it "correctly treats pipe marks '|' in input (regression test)" do
      expect(Monetize.extract_cents('100|0')).to eq Monetize.extract_cents('100!0')
    end
  end

  context 'given the same inputs to .parse and .from_*' do
    it 'gives the same results' do
      expect(4.635.to_money).to eq '4.635'.to_money
    end
  end
end
