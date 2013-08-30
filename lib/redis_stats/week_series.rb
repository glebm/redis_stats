module RedisStats
  class WeekSeries < EnumerableSeries
    protected
    def x_from_i(i)
      from + i.weeks
    end

    def x_to_i(date)
      distance_in_weeks(date, from)
    end

    def x_from_s(val)
      if val.present?
        cwyear, cweek = val.split('w')
        Date.commercial(cwyear.to_i, cweek.to_i, 1)
      end
    end

    def x_to_s(val)
       if val
         "#{val.cwyear}w#{val.cweek}"
       end
    end
  end
end