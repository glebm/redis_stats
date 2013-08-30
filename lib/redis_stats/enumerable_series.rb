require 'redis_stats/redis_series'
module RedisStats
  # abstract class, requires: 
  # * x_from_i
  # * x_to_i
  # * x_from_s
  # * x_to_s
  class EnumerableSeries
    include RedisSeries
    delegate :key, :size, :each, to: :@list

    def initialize(key)
      @list = IntSeries.new(key)
    end

    def []=(date, value)
      self.from ||= date
      @list[x_to_i date] = value
    end

    def [](date)
      @list[x_to_i(date)]
    end

    def from
      x_from_s redis.get(from_key)
    end

    def from=(value)
      redis.set from_key, x_to_s(value)
    end

    def to
      x_from_i(size)
    end

    private

    def from_key
      "#{key}:d-from"
    end

    def to_key
      "#{key}:d-to"
    end
  end
end