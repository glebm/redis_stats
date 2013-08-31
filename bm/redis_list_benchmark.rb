require 'active_support/number_helper'
require 'benchmark_helper'
class RedisListBenchmark
  include RedisStats
  include ActiveSupport::NumberHelper

  def bm_plot(max = 100_000, step = 1_000)
    x = []
    y1 = []
    y2 = []
    (step..max).step(step).each do |i|
      x << i
      y1 << single_list_memory(i) / (1024 * 1024).to_f
      y2 << sliced_list_memory(i) / (1024 * 1024).to_f
    end
    BenchmarkHelper.plot(x, y1, y2) do |plot|
      plot.output 'bm/plot.png'
      plot.title "Regular vs Sliced (#{slice_size} per slice)"
      plot.terminal 'pngcairo'
    end
  end

  def bm_memory(size = 1_000_000)
    a = single_list_memory size
    b = sliced_list_memory size
    puts "Single list #{number_to_delimited size}: #{number_to_human_size a}"
    puts "Sliced list #{number_to_delimited size}: #{number_to_human_size b}"
    puts "#{100 - (b.to_f / a * 100).round}% savings"
  end

  def single_list_memory(size)
    redis.flushall
    vals = (1..size).to_a
    redis.rpush 'list', vals
    used_memory_bytes('list')
  end

  def sliced_list_memory(size)
    redis.flushall
    vals = (1..size).to_a
    IntSeries.new('sliced').rpush(vals)
    used_memory_bytes('sliced:*')
  end

  def slice_size
    Redis.current.config('GET', 'list-max-ziplist-entries').last.try(:to_i)
  end

  private
  def used_memory_bytes(pattern)
    keys = redis.keys pattern
    r = 0
    keys.each { |key|
      redis.debug("object", key) =~ /serializedlength:(\d*)/
      r += $1.to_i
    }
    r
  end

  def redis
    Redis.current
  end
end