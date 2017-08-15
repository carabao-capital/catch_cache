module CatchCache
  module Flush
    class << self
      def included(klass)
        klass.class_eval do
          extend ClassMethods
          after_commit :flush_cache!

          define_method(:flush_cache!) do
            key_callbacks = ClassMethods.key_callbacks

            key_callbacks.keys.each do |key|
              # Get the uniq id defined in the AR model
              binding.pry
              begin
                uniq_id = instance_exec(&key_callbacks[key])
                # Build the redis cache key
                cache_key = "#{key.to_s}_#{uniq_id}"
                redis = Redis.new
                # Flush the key by setting it to nil
                redis.set(cache_key, nil)
              rescue NameError => e
                # Nothing was flushed because of an error"
              end
            end
          end

        end
      end

      module ClassMethods
        mattr_accessor :key_callbacks

        # here, we store the callbacks
        # that builds the uniq identifiers
        # for our caches
        self.key_callbacks = {}

        # a key_callback is a proc that returns
        # the unique identifier that will be
        # concatinated to the cache name
        #
        # An example of a redis key is
        # "lead_logs_cache_<uniq_id>"
        def cache_id(*args)
          key_callbacks[args.first] = args.second
        end
      end
    end
  end
end
