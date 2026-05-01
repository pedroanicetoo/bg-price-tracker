class SessionManagerService
  SESSION_PREFIX = "session:".freeze
  SESSION_TTL    = 30.minutes.to_i

  def initialize(redis: default_redis)
    @redis = redis
  end

  def get(phone)
    raw = @redis.get(key(phone))
    return nil unless raw

    JSON.parse(raw, symbolize_names: true)
  end

  def set(phone, state:, data: {})
    payload = {
      state:      state.to_s,
      data:       data,
      updated_at: Time.current.iso8601
    }
    @redis.setex(key(phone), SESSION_TTL, payload.to_json)
  end

  def clear(phone)
    @redis.del(key(phone))
  end

  def exists?(phone)
    @redis.exists?(key(phone))
  end

  def get_nested(phone, sub_key)
    session = get(phone)
    session&.dig(:data, sub_key.to_sym)
  end

  def set_nested(phone, sub_key, value)
    session = get(phone) || { state: "active", data: {} }
    data    = (session[:data] || {}).merge(sub_key.to_s => value)
    set(phone, state: session[:state] || "active", data: data)
  end


  def clear_nested(phone, sub_key)
    session = get(phone)
    return unless session

    data = (session[:data] || {}).except(sub_key.to_s, sub_key.to_sym)
    set(phone, state: session[:state] || "active", data: data)
  end

  private

  def key(phone)
    "#{SESSION_PREFIX}#{phone}"
  end

  def default_redis
    Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"))
  end
end
