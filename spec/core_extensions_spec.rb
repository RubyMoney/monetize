# encoding: utf-8

require "spec_helper"
require "monetize"
require "monetize/core_extensions"

describe Monetize, "core extensions" do
  describe NilClass do
    describe "#to_money" do
      it "work as documented" do
        money = nil.to_money
        expect(money.cents).to eq 0
        expect(money.currency).to eq Money.default_currency
      end

      it "accepts optional currency" do
        expect(nil.to_money('USD')).to eq Money.new(nil, 'USD')
        expect(nil.to_money('EUR')).to eq Money.new(nil, 'EUR')
      end
    end
  end

  describe Numeric do
    describe "#to_money" do
      it "work as documented" do
        money = 1234.to_money
        expect(money.cents).to eq 1234_00
        expect(money.currency).to eq Money.default_currency

        money = 100.37.to_money
        expect(money.cents).to eq 100_37
        expect(money.currency).to eq Money.default_currency

        money = BigDecimal.new('1234').to_money
        expect(money.cents).to eq 1234_00
        expect(money.currency).to eq Money.default_currency
      end

      it "accepts optional currency" do
        expect(1234.to_money('USD')).to eq Money.new(123400, 'USD')
        expect(1234.to_money('EUR')).to eq Money.new(123400, 'EUR')
      end

      it "respects :subunit_to_unit currency property" do
        expect(10.to_money('USD')).to eq Money.new(10_00, 'USD')
        expect(10.to_money('TND')).to eq Money.new(10_000, 'TND')
        expect(10.to_money('JPY')).to eq Money.new(10, 'JPY')
      end

      specify "GH-15" do
        amount = 555.55.to_money
        expect(amount).to eq Money.new(55555)
      end
    end
  end

  describe String do
    describe "#to_money" do

      STRING_TO_MONEY = {
        "20.15"           => Money.new(20_15)                 ,
        "100"             => Money.new(100_00)                ,
        "100.37"          => Money.new(100_37)                ,
        "100,37"          => Money.new(100_37)                ,
        "100 000"         => Money.new(100_000_00)            ,
        "100,000.00"      => Money.new(100_000_00)            ,
        "1,000"           => Money.new(1_000_00)              ,
        "-1,000"          => Money.new(-1_000_00)             ,
        "1,000.5"         => Money.new(1_000_50)              ,
        "1,000.51"        => Money.new(1_000_51)              ,
        "1,000.505"       => Money.new(1_000_51)              ,
        "1,000.504"       => Money.new(1_000_50)              ,
        "1,000.0000"      => Money.new(1_000_00)              ,
        "1,000.5000"      => Money.new(1_000_50)              ,
        "1,000.5099"      => Money.new(1_000_51)              ,
        "1.550"           => Money.new(1_55)                  ,
        "25."             => Money.new(25_00)                 ,
        ".75"             => Money.new(75)                    ,

        "7.21K"           => Money.new(7_210_00)              ,
        "1M"              => Money.new(1_000_000_00)          ,
        "1.2M"            => Money.new(1_200_000_00)          ,
        "1.37M"           => Money.new(1_370_000_00)          ,
        "3.1415927M"      => Money.new(3_141_592_70)          ,
        ".42B"            => Money.new(420_000_000_00)        ,
        "5T"              => Money.new(5_000_000_000_000_00)  ,

        "100 USD"         => Money.new(100_00, "USD")         ,
        "-100 USD"        => Money.new(-100_00, "USD")        ,
        "100 EUR"         => Money.new(100_00, "EUR")         ,
        "100.37 EUR"      => Money.new(100_37, "EUR")         ,
        "100,37 EUR"      => Money.new(100_37, "EUR")         ,
        "100,000.00 USD"  => Money.new(100_000_00, "USD")     ,
        "100.000,00 EUR"  => Money.new(100_000_00, "EUR")     ,
        "1,000 USD"       => Money.new(1_000_00, "USD")       ,
        "-1,000 USD"      => Money.new(-1_000_00, "USD")      ,
        "1,000.5500 USD"  => Money.new(1_000_55, "USD")       ,
        "-1,000.6500 USD" => Money.new(-1_000_65, "USD")      ,
        "1.550 USD"       => Money.new(1_55, "USD")           ,

        "USD 100"         => Money.new(100_00, "USD")         ,
        "EUR 100"         => Money.new(100_00, "EUR")         ,
        "EUR 100.37"      => Money.new(100_37, "EUR")         ,
        "CAD -100.37"     => Money.new(-100_37, "CAD")        ,
        "EUR 100,37"      => Money.new(100_37, "EUR")         ,
        "EUR -100,37"     => Money.new(-100_37, "EUR")        ,
        "USD 100,000.00"  => Money.new(100_000_00, "USD")     ,
        "EUR 100.000,00"  => Money.new(100_000_00, "EUR")     ,
        "USD 1,000"       => Money.new(1_000_00, "USD")       ,
        "USD -1,000"      => Money.new(-1_000_00, "USD")      ,
        "USD 1,000.9000"  => Money.new(1_000_90, "USD")       ,
        "USD -1,000.090"  => Money.new(-1_000_09, "USD")      ,
        "USD 1.5500"      => Money.new(1_55, "USD")           ,

        "$100 USD"        => Money.new(100_00, "USD")         ,
        "$1,194.59 USD"   => Money.new(1_194_59, "USD")       ,
        "$-1,955 USD"     => Money.new(-1_955_00, "USD")      ,
        "$1,194.5900 USD" => Money.new(1_194_59, "USD")       ,
        "$-1,955.000 USD" => Money.new(-1_955_00, "USD")      ,
        "$1.99000 USD"    => Money.new(1_99, "USD")           ,
      }

      it "works as documented" do
        STRING_TO_MONEY.each do |string, money|
          expect(string.to_money).to eq money
        end
      end

      it "coerces input to string" do
        expect(Monetize.parse(20, "USD")).to eq Money.new(20_00, "USD")
      end

      it "accepts optional currency" do
        expect("10.10".to_money('USD')).to eq Money.new(1010, 'USD')
        expect("10.10".to_money('EUR')).to eq Money.new(1010, 'EUR')
        expect("10.10 USD".to_money('USD')).to eq Money.new(1010, 'USD')
      end

      it "uses parsed currency, even if currency is passed" do
        expect("10.10 USD".to_money("EUR")).to eq(Money.new(1010, "USD"))
      end

      it "ignores unrecognized data" do
        expect("hello 2000 world".to_money).to eq Money.new(2000_00)
      end

      it "respects :subunit_to_unit currency property" do
        expect("1".to_money("USD")).to eq Money.new(1_00,  "USD")
        expect("1".to_money("TND")).to eq Money.new(1_000, "TND")
        expect("1".to_money("JPY")).to eq Money.new(1,     "JPY")
        expect("1.5".to_money("KWD").cents).to eq 1500
      end
    end

    describe "#to_currency" do
      it "converts String to Currency" do
        expect("USD".to_currency).to eq Money::Currency.new("USD")
        expect("EUR".to_currency).to eq Money::Currency.new("EUR")
      end

      it "raises Money::Currency::UnknownCurrency with unknown Currency" do
        expect { "XXX".to_currency }.to raise_error(Money::Currency::UnknownCurrency)
        expect { " ".to_currency }.to raise_error(Money::Currency::UnknownCurrency)
      end
    end
  end

  describe Hash do
    describe "#to_money" do

      context "when currency is present in hash" do
        subject(:hash){ { cents: 5, currency: "EUR" } }

        it "converts Hash to Money using key from hash" do
          expect(hash.to_money).to eq(Money.new(5, "EUR"))
        end
      end

      context "when currency is passed as argument" do
        subject(:hash){ { cents: 10 } }

        it "converts Hash to Money using passed currency argument" do
          expect(hash.to_money("JPY")).to eq(Money.new(10, "JPY"))
        end
      end

      context "when no currency is passed" do
        subject(:hash){ { cents: 123 } }

        before { allow(Money).to receive(:default_currency).and_return("USD") }

        it "converts Hash to Money using default value" do
          expect(hash.to_money("USD")).to eq(Money.new(123, "USD"))
        end
      end

    end
  end

  describe Symbol do
    describe "#to_currency" do
      it "converts Symbol to Currency" do
        expect(:usd.to_currency).to eq Money::Currency.new("USD")
        expect(:ars.to_currency).to eq Money::Currency.new("ARS")
      end

      it "is case-insensitive" do
        expect(:EUR.to_currency).to eq Money::Currency.new("EUR")
      end

      it "raises Money::Currency::UnknownCurrency with unknown Currency" do
        expect { :XXX.to_currency }.to raise_error(Money::Currency::UnknownCurrency)
        expect { :" ".to_currency }.to raise_error(Money::Currency::UnknownCurrency)
      end
    end
  end
end
