require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)
task :default => :spec

task :bm do
  $: << File.expand_path('lib', File.dirname(__FILE__)) << File.expand_path('bm', File.dirname(__FILE__))
  require 'redis_stats'
  require 'redis_list_benchmark'
  RedisListBenchmark.new.bm_all
end