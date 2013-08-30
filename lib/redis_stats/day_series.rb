require 'redis_stats/enumerable_series'
module RedisStats
  class DaySeries < EnumerableSeries
    protected
    def x_from_i(i)
      from + i
    end

    def x_to_i(date)
      date - from
    end

    def x_from_s(val)
      Date.parse val if val
    end

    def x_to_s(val)
      val.strftime '%Y-%m-%d' if val
    end
  end
end