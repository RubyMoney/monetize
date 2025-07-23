# encoding: utf-8

require 'money'

RSpec.configure do |config|
  config.order = 'random'
  if ENV['MODE'] == 'strict'
    config.before(:each) do
      Monetize.default_parser = :strict
    end
  end
end

