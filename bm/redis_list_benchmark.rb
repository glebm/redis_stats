require 'active_support/number_helper'
require 'benchmark_helper'

# requires gnuplot with cairo
#   brew install gnuplot --cairo
class RedisListBenchmark
  include RedisStats
  include ActiveSupport::NumberHelper

  def bm_all
    bm_plot_memory 2_000_000, 50_000
    bm_memory 2_000_000
    bm_speed 3_000_000, 100
  end


  def bm_plot_memory(max = 100_000, step = 1_000)
    redis.flushall
    x = []
    y1 = []
    y2 = []
    (step..max).step(step).each do |i|
      vals = i.times.map { rand(10) }
      puts "bm_plot_memory: #{number_to_delimited i} / #{number_to_delimited max}"
      x << i
      y1 << single_list_memory(vals) / (1024 * 1024).to_f
      y2 << sliced_list_memory(vals) / (1024 * 1024).to_f
    end
    BenchmarkHelper.plot(x, {data: y1, label: 'Native list'}, {data: y2, label: 'Partitioned list'}) do |plot|
      plot.title "Regular vs Partitioned (list-max-ziplist-entries: #{slice_size})"
      plot.style 'fill transparent'
      plot.xlabel 'List elements'
      plot.ylabel 'Size, MB'
      plot.output 'bm/plot.png'
      plot.terminal 'pngcairo size 1200, 600 font "Arial,20"'
    end
  end


  def bm_speed(size = 1_000_000, reads = 1000)
    puts "bm_speed: #{number_to_delimited size} keys, #{number_to_delimited reads} reads"
    redis.flushall
    vals = size.times.map { rand(10) }
    read_at = (1..reads).map { |i|
      from = rand(size)
      to = [from + rand(1000), size - 1].min
      [from, to]
    }
    sliced = IntSeries.new('sliced')
    vals.each_slice(1_000_000) do |v|
      redis.rpush 'list', v
      sliced.rpush v
    end
    Benchmark.bm(20) do |x|
      x.report('regular') {
        read_at.each { |r| redis.lrange 'list', r[0], r[1] }
      }
      x.report('partitioned') {
        read_at.each { |r| sliced.range r[0], r[1] }
      }
    end
  end

  def bm_memory(size = 1_000_000)
    redis.flushall
    vals = size.times.map { rand(10) }
    puts "bm_memory: #{number_to_delimited size} keys"
    a = single_list_memory vals
    b = sliced_list_memory vals
    puts "Single list #{number_to_delimited size}: #{number_to_human_size a}"
    puts "Sliced list #{number_to_delimited size}: #{number_to_human_size b}"
    puts "#{100 - (b.to_f / a * 100).round}% savings"
  end

  def single_list_memory(vals)
    redis.flushall
    vals.each_slice(1_000_000) { |v| redis.rpush 'list', v }
    used_memory_bytes('list')
  end

  def sliced_list_memory(vals)
    redis.flushall
    series = IntSeries.new('sliced')
    vals.each_slice(1_000_000) { |v| series.rpush v }
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