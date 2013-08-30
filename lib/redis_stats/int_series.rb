require 'redis_stats/redis_series'

# int series list
# stored in many lists of max size list-max-ziplist-entries
# any-range int indexes (e.g from -10 to 15)
# auto-extends
module RedisStats
  class IntSeries
    include RedisSeries
    include Enumerable

    def initialize(key, opts = {})
      @key               = key
      @config_slice_size = opts[:list_slice_size] || Redis.current.config('GET', 'list-max-ziplist-entries').last.try(:to_i) || 512
      if @config_slice_size != self.slice_size
        Rails.logger.warn("List #{key} has slice size #{@config_slice_size}, please resize for maximum efficiency")
      end
    end

    def each
      (from / slice_size .. to / slice_size).each do |i|
        redis.lrange(slice_key(i), 0, -1).each do |value|
          yield value
        end
      end
    end

    def []=(idx, value)
      self.from ||= idx
      self.to   ||= idx
      to, from  = self.to, self.from

      rpush *([0] * (idx - to)) if idx > to
      lpush *([0] * (from - idx - 1)) if idx < from

      if idx < from
        lpush value
      elsif idx >= to
        rpush value
      else
        set_without_extend idx, value
      end

      value
    end

    def [](idx)
      redis.lindex *key_pos(idx)
    end

    def <<(value)
      self[size] = value
      self
    end

    def from=(value)
      redis.set from_key, value
      set_size
    end

    def to=(value)
      redis.set to_key, value
      set_size
    end

    def from
      redis.get(from_key).try(:to_i)
    end

    def to
      redis.get(to_key).try(:to_i)
    end

    def size
      to && from ? to - from : 0
    end

    def slice_size
      get_or_set_default(slice_size_key, @config_slice_size).to_i
    end

    def restructure!(new_slize_size)
      redis.multi do
        values = to_a
        destroy
        redis.set slice_size_key, new_slize_size
        values.each { |v| self << v }
      end
    end

    def rpush(*vals)
      self.from = self.to = 0 unless self.from
      i = to = self.to
      while i <= to + vals.length
        slice, _ = key_pos(i)
        space    = slice_size - redis.llen(slice)
        push = vals[i - to...i - to + space] || []
        break if push.empty?
        redis.rpush slice, push
        i += push.length
      end
      self.to += vals.length
    end

    def lpush(*vals)
      self.from = self.to = 0 unless self.from
      from = self.from
      i = from - 1
      while i >= from - vals.length
        slice, _ = key_pos(i)
        space    = slice_size - redis.llen(slice)
        push = vals[(from - i - 1)...(from - i - 1) + space] || []
        break if push.empty?
        redis.lpush slice, push
        i -= push.length
      end
      self.from -= vals.length
    end

    private

    def set_without_extend(idx, val)
      slice, i = key_pos(idx)
      redis.lset slice, i, val
    end

    def from_key
      "#{key}:from"
    end

    def to_key
      "#{key}:to"
    end

    # combined size
    def size_key
      "#{key}:size"
    end

    # max size of each slice
    def slice_size_key
      "#{key}:slice_size"
    end

    def slice_key(i)
      "#{key}:#{i}"
    end

    def set_size
      to, from = self.to, self.from
      redis.set size_key, to - from if to && from
    end

    def key_pos(idx)
      s_i, i = pos(idx)
      [slice_key(s_i), i]
    end

    def pos(idx)
      [idx / slice_size, idx % slice_size]
    end

    def redis
      Redis.current
    end
  end
end