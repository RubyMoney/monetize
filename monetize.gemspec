# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "monetize/version"

Gem::Specification.new do |spec|
  spec.name          = "monetize"
  spec.version       = Monetize::VERSION
  spec.authors       = ["Shane Emmons"]
  spec.email         = ["shane@emmons.io"]
  spec.description   = "A library for converting various objects into `Money` objects."
  spec.summary       = "A library for converting various objects into `Money` objects."
  spec.homepage      = "https://github.com/RubyMoney/monetize"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "money", "~> 6.6"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.0.0.beta1"
end
