require 'active_support/number_helper'
require 'benchmark_helper'

# requires gnuplot with cairo
#   brew install gnuplot --cairo
class RedisListBenchmark
  include RedisStats
  include ActiveSupport::NumberHelper

  def bm_all
    bm_plot_memory 1_000_000, 10_000
    bm_memory 2_000_000
    bm_speed 1_000_000
  end


  def bm_plot_memory(max = 100_000, step = 1_000)
    x = []
    y1 = []
    y2 = []
    (step..max).step(step).each do |i|
      puts "bm_plot_memory: #{number_to_human i} / #{number_to_human max}"
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


  def bm_speed(keys = 1_000_000)
    redis.flushall
    vals = (1..keys).to_a.shuffle
    access_ranges = (1..1000).map { |i|
      from = rand(1_000_000)
      to = [from + rand(10000), keys - 1].max
      [from, to]
    }
    redis.rpush 'list', vals
    sliced = IntSeries.new('sliced')
    sliced.rpush vals
    Benchmark.bm do |x|
      x.report('list') {
        access_ranges.each { |r| redis.lrange 'list', r[0], r[1] }
      }
      x.report('sliced list') {
        access_ranges.each { |r| sliced.range r[0], r[1] }
      }
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