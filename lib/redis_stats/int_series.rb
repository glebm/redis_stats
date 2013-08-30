# int series list
# stored in many lists of max size list-max-ziplist-entries
class IntSeries
  include RedisList
  include Enumerable

  def initialize(key, max_per_list = nil)
    @key        = key
    @config_slice_size = max_per_list || Redis.current.config('GET', 'list-max-ziplist-entries').last.try(:to_i) || 512
    if @config_slice_size != self.slice_size
      Rails.logger.warn("List #{key} has slice size #{@config_slice_size}, please resize for maximum efficiency")
    end
  end

  def each
    (0..length / slice_size).each do |i|
      redis.lrange(slice_key(i), 0, -1).each do |value|
        yield value
      end
    end
  end

  def []=(idx, value)
    slice_i, i = pos(idx)
    slice      = slice_key(slice_i)
    len        = redis.llen(idx)
    # pad with 0 if adding past the end
    if i > len
      pad = idx - len
      redis.rpush slice, [0] * pad
    end
    if len > i
      redis.lset slice, i, value
    else
      redis.rpush slice, value
    end
    redis.set from_key, [idx, from].min
    redis.set to_key, [idx, to].max
    value
  end

  def [](idx)
    slice_i, i = pos(idx)
    redis.lindex slice_key(slice_i), i
  end

  def <<(value)
    self[size] = value
  end

  def from
    redis.get(from_key).to_i
  end

  def to
    redis.get(to_key).to_i
  end

  def size
    to - from
  end

  def slice_size
    get_or_set_default(slice_size_key, @config_slice_size).to_i
  end

  def resize!(new_slize_size)
    redis.multi do
      values = to_a
      destroy
      redis.set slice_size_key, new_slize_size
      values.each { |v| self << v }
    end
  end

  private

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

  def pos(idx)
    slice_i   = idx / slice_size
    slice_pos = idx % slice_size
    [slice_i, slice_pos]
  end

  def redis
    Redis.current
  end
end