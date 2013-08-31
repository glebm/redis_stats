module RedisStats
  module RedisSeries
    include Enumerable

    attr_reader :key

    def transaction(&block)
      redis.multi &block
    end

    def length
      size
    end

    def count
      size
    end

    def begin
      from
    end

    def end
      to
    end

    def memory_size
      keys = redis.keys("#{key}:*")

    end

    protected

    # get (or set default)
    def get_or_set_default(key, default = nil)
      redis.get(key) || default.presence && redis.set(key, default) && default
    end

    def destroy
      keys = redis.keys("#{key}:*") || []
      redis.del *keys if keys.present?
    end

    def redis
      Redis.current
    end
  end
end