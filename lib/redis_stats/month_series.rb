module RedisStats
  class MonthSeries < EnumerableSeries
    protected
    def x_from_i(i)
      from + i.months
    end

    def x_to_i(date)
      distance_in_months(date, from)
    end

    def x_from_s(val)
      Date.parse val + '-15' if val
    end

    def x_to_s(val)
      val.strftime '%Y-%m' if val
    end
  end
end