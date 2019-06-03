# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'monetize/version'
require 'English'

Gem::Specification.new do |spec|
  spec.name          = 'monetize'
  spec.version       = Monetize::VERSION
  spec.authors       = ['Shane Emmons', 'Anthony Dmitriyev']
  spec.email         = ['shane@emmons.io', 'anthony.dmitriyev@gmail.com']
  spec.description   = 'A library for converting various objects into `Money` objects.'
  spec.summary       = 'A library for converting various objects into `Money` objects.'
  spec.homepage      = 'https://github.com/RubyMoney/monetize'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'money', '~> 6.12'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake', '~> 10.2'
  spec.add_development_dependency 'rspec', '~> 3.0'

  if spec.respond_to?(:metadata)
    spec.metadata['changelog_uri'] = 'https://github.com/RubyMoney/monetize/blob/master/CHANGELOG.md'
    spec.metadata['source_code_uri'] = 'https://github.com/RubyMoney/monetize/'
    spec.metadata['bug_tracker_uri'] = 'https://github.com/RubyMoney/monetize/issues'
  end
end
