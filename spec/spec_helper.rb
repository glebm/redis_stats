ENV['RAKE_ENV'] = 'test' unless 'test' == ENV['RAKE_ENV']

require 'rspec/autorun'
$: << File.expand_path('../lib', __FILE__)
require 'redis_stats'
require 'rake'
Dir['spec/support/**/*.rb'].each { |f| require "./#{f}" }

include RedisStats
require 'mock_redis'

RSpec.configure do |config|
end

