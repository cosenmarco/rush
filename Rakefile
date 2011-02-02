require 'rubygems'
require 'bundler/setup'
require 'rspec'
require 'rspec/core/rake_task'
require 'yard'

Bundler::GemHelper.install_tasks

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :default => :spec

YARD::Rake::YardocTask.new
