module RedisStats
  module DateHelpers
    def distance_in_weeks(b, a)
      (b.cwyear - a.cwyear) * 12 + (b.month - a.month) * 52 + (b.cweek - a.cweek)
    end

    def distance_in_months(b, a)
      (b.cwyear - a.cwyear) * 12 + (b.month - a.month)
    end
  end
end