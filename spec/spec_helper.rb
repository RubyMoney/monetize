# encoding: utf-8

require 'money'

Money.default_currency = 'USD'

RSpec.configure do |config|
  config.order = 'random'
end
