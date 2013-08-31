module RedisEnv
  def mock_redis!
    Redis.current = MockRedis.new
  end

  def real_redis!
    Redis.current = Redis.new(db: 13)
  end

  def clear_redis!
    keys = Redis.current.keys('*')
    Redis.current.del *keys if keys.present?
  end

  def self.included(base)
    default = :mock
    base.class_eval do
      around(:each, redis: :real) do |e|
        real_redis!
        e.run
        clear_redis!
      end
      around(:each, redis: :mock) do |e|
        real_redis!
        e.run
        clear_redis!
      end
    end
  end
end