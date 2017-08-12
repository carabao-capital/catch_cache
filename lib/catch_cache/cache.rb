module CatchCache
  module Cache
    class << self
      def included(klass)
        klass.class_eval do
          def self.catch_then_cache(redis_key, &block)
            redis = Redis.new
            val = redis.get(redis_key)

            # retrieve the cache with redis_key as its key
            cache = JSON.parse(val.blank? ? "[]" : val)

            if cache.blank?
              timeline_logs = block.call
              redis.set(redis_key, timeline_logs.to_json)
              cache = JSON.parse(redis.get(redis_key))
            end

            cache
          end

          def catch_then_cache(redis_key, &block)
            redis = Redis.new
            val = redis.get(redis_key)

            # retrieve the cache with redis_key as its key
            cache = JSON.parse(val.blank? ? "[]" : val)

            if cache.blank?
              timeline_logs = block.call
              redis.set(redis_key, timeline_logs.to_json)
              cache = JSON.parse(redis.get(redis_key))
            end

            cache
          end
        end
      end
    end
  end
end
