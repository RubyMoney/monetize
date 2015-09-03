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

        it 'parses formatted inputs with Euros passed as a symbol' do
          expect(Monetize.parse('€5.95')).to eq Money.new(595, 'EUR')
        end

        it 'parses formatted inputs with Euros passed as a symbol with surrounding space' do
          expect(Monetize.parse(' €5.95 ')).to eq Money.new(595, 'EUR')
        end

        it 'parses formatted inputs with British Pounds Sterling passed as a symbol' do
          expect(Monetize.parse('£9.99')).to eq Money.new(999, 'GBP')
        end

        it 'parses formatted inputs with British Pounds Sterling passed as a lira sign symbol' do
          expect(Monetize.parse('₤9.99')).to eq Money.new(999, 'GBP')
        end

        it 'parses formatted inputs with South African Rand passed as a symbol' do
          expect(Monetize.parse('R9.99')).to eq Money.new(999, 'ZAR')
        end

        it 'parses formatted inputs with Brazilian real passed as a symbol' do
          expect(Monetize.parse('R$R9.99')).to eq Money.new(999, 'BRL')
        end

        it 'parses formatted inputs with Japanese Yen passed as a symbol' do
          expect(Monetize.parse('¥999')).to eq Money.new(999, 'JPY')
        end

        it 'parses formatted inputs with Canadian Dollar passed as a symbol' do
          expect(Monetize.parse('C$9.99')).to eq Money.new(999, 'CAD')
        end

        it 'should assume default currency if not a recognised symbol' do
          expect(Monetize.parse('L9.99')).to eq Money.new(999, 'USD')
        end

        it 'parses formatted inputs without currency detection when overridden' do
          expect(Monetize.parse('£9.99', nil, assume_from_symbol: false)).to eq Money.new(999, 'USD')
        end

        it 'parses formatted inputs with minus sign and currency symbol' do
          expect(Monetize.parse('-€9.99')).to eq Money.new(-999, 'EUR')
          expect(Monetize.parse('-£9.99')).to eq Money.new(-999, 'GBP')
          expect(Monetize.parse('-R$R9.99')).to eq Money.new(-999, 'BRL')
          expect(Monetize.parse('-¥999')).to eq Money.new(-999, 'JPY')
          expect(Monetize.parse('-C$9.99')).to eq Money.new(-999, 'CAD')
        end

        it 'parses formatted inputs with plus and GBP passed as symbol' do
          expect(Monetize.parse('+€9.99')).to eq Money.new(999, 'EUR')
          expect(Monetize.parse('+£9.99')).to eq Money.new(999, 'GBP')
          expect(Monetize.parse('+R$R9.99')).to eq Money.new(999, 'BRL')
          expect(Monetize.parse('+¥999')).to eq Money.new(999, 'JPY')
          expect(Monetize.parse('+C$9.99')).to eq Money.new(999, 'CAD')
        end

        it 'parses formatted inputs with currency symbol and postfix minus sign' do
          expect(Monetize.parse('€9.99-')).to eq Money.new(-999, 'EUR')
        end

        it 'parses formatted inputs with currency symbol and postfix plus sign' do
          expect(Monetize.parse('€9.99+')).to eq Money.new(999, 'EUR')
        end

        it 'parses formatted inputs with amounts given with suffixes' do
          expect(Monetize.parse('$1.26K')).to eq Money.new(1_260_00, 'USD')
          expect(Monetize.parse('$126.36M')).to eq Money.new(126_360_000_00, 'USD')
          expect(Monetize.parse('€.45B')).to eq Money.new(450_000_000_00, 'EUR')
          expect(Monetize.parse('-$2.45B')).to eq Money.new(-2_450_000_000_00, 'USD')
          expect(Monetize.parse('€1.65T')).to eq Money.new(1_650_000_000_000_00, 'EUR')
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

    it 'does not return a price if there is a price range' do
      expect { Monetize.parse('$5.95-10.95') }.to raise_error ArgumentError
      expect { Monetize.parse('$5.95 - 10.95') }.to raise_error ArgumentError
      expect { Monetize.parse('$5.95 - $10.95') }.to raise_error ArgumentError
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

    it 'raises ArgumentError when unable to detect polarity' do
      expect { Monetize.parse('-$5.95-') }.to raise_error ArgumentError
    end

    it 'parses correctly strings with exactly 3 decimal digits' do
      expect(Monetize.parse('6,534', 'EUR')).to eq Money.new(653, 'EUR')
      expect(Monetize.parse('6.534', 'EUR')).to eq Money.new(653, 'EUR')

      Monetize.enforce_currency_delimiters = true
      expect(Monetize.parse('6.534', 'EUR')).to eq Money.new(6_534_00, 'EUR')
      Monetize.enforce_currency_delimiters = false
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
      expect(Monetize.from_bigdecimal(BigDecimal.new('1'))).to eq Money.new(1_00)
      expect(Monetize.from_bigdecimal(BigDecimal.new('1'))).to eq Money.new(1_00, 'USD')
      expect(Monetize.from_bigdecimal(BigDecimal.new('1'), 'EUR')).to eq Money.new(1_00, 'EUR')
    end

    it 'respects :subunit_to_unit currency property' do
      expect(Monetize.from_bigdecimal(BigDecimal.new('1'), 'USD')).to eq Money.new(1_00, 'USD')
      expect(Monetize.from_bigdecimal(BigDecimal.new('1'), 'TND')).to eq Money.new(1_000, 'TND')
      expect(Monetize.from_bigdecimal(BigDecimal.new('1'), 'JPY')).to eq Money.new(1, 'JPY')
    end

    it 'accepts a currency options' do
      m = Monetize.from_bigdecimal(BigDecimal.new('1'))
      expect(m.currency).to eq Money.default_currency

      m = Monetize.from_bigdecimal(BigDecimal.new('1'), Money::Currency.wrap('EUR'))
      expect(m.currency).to eq Money::Currency.wrap('EUR')

      m = Monetize.from_bigdecimal(BigDecimal.new('1'), 'EUR')
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
        expect(Monetize.from_bigdecimal(BigDecimal.new('1'))).to eq Money.new(100)
        expect(Monetize.from_bigdecimal(BigDecimal.new('1.23456'))).to eq Money.new(123.456)
        expect(Monetize.from_bigdecimal(BigDecimal.new('-1.23456'))).to eq Money.new(-123.456)
        expect(Monetize.from_bigdecimal(BigDecimal.new('1.23456'))).to eq Money.new(123.456, 'USD')
        expect(Monetize.from_bigdecimal(BigDecimal.new('1.23456'), 'EUR')).to eq Money.new(123.456, 'EUR')

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
      expect(Monetize.from_numeric(BigDecimal.new('1'))).to eq Money.new(1_00)
    end

    it 'raises ArgumentError with unsupported argument' do
      expect { Monetize.from_numeric('100') }.to raise_error(ArgumentError)
    end

    it 'optimizes workload' do
      expect(Monetize).to receive(:from_fixnum).with(1, 'USD').and_return(Money.new(1_00, 'USD'))
      expect(Monetize.from_numeric(1, 'USD')).to eq Money.new(1_00, 'USD')
      expect(Monetize).to receive(:from_bigdecimal).with(BigDecimal.new('1.0'), 'USD').
        and_return(Money.new(1_00, 'USD'))
      expect(Monetize.from_numeric(1.0, 'USD')).to eq Money.new(1_00, 'USD')
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
