module RedisList
  attr_reader :key
  protected

  # returns redis result or default or nil if default is blank
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

  alias_method :length, :size
  alias_method :count, :size
  alias_method :begin, :from
  alias_method :end, :to
end