source 'https://rubygems.org'

gem 'coveralls', '>= 0.8.20', require: false

# JSON gem no longer supports ruby < 2.0.0
if defined?(JRUBY_VERSION)
  gem 'json'
elsif RUBY_VERSION =~ /^1/
  gem 'json', '~> 1.8.3'
  gem 'tins', '~> 1.6.0'
  gem 'term-ansicolor', '~> 1.3.0'
end

gemspec
