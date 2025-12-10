# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "monetize/version"

Gem::Specification.new do |s|
  s.name        = "monetize"
  s.version     = Monetize::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Shane Emmons", "Anthony Dmitriyev"]
  s.email       = ["shane@emmons.io", "anthony.dmitriyev@gmail.com"]
  s.homepage    = "https://github.com/RubyMoney/monetize"
  s.summary     = "A library for converting various objects into `Money` objects."
  s.description = "A library for converting various objects into `Money` objects."
  s.license     = "MIT"

  s.add_dependency "money", "~> 7.0"

  s.required_ruby_version = ">= 3.1"

  s.files         = `git ls-files -z -- lib/* CHANGELOG.md LICENSE monetize.gemspec README.md`.split("\x0")
  s.require_paths = ["lib"]

  if s.respond_to?(:metadata)
    s.metadata["changelog_uri"] = "https://github.com/RubyMoney/monetize/blob/master/CHANGELOG.md"
    s.metadata["source_code_uri"] = "https://github.com/RubyMoney/monetize/"
    s.metadata["bug_tracker_uri"] = "https://github.com/RubyMoney/monetize/issues"
    s.metadata["rubygems_mfa_required"] = "true"
  end
end
