require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

task default: :spec

RSpec::Core::RakeTask.new

task :environment do
  require_relative 'lib/monetize'
end

desc 'Start a console with library loaded'
task console: :environment do
  require 'irb'
  require 'irb/completion'
  ARGV.clear
  IRB.start
end
