module CatchCache
  module Flush
    class << self
      def included(klass)
        klass.class_eval do
          extend ClassMethods
          after_commit :flush_cache!

          define_method(:flush_cache!) do
            key_callbacks = ClassMethods.key_callbacks


            key_callbacks.keys.select{|key| key.to_s.split("__").last == self.class.name.underscore }.each do |key|
              # Get the uniq id defined in the AR model
              begin
                uniq_id = instance_exec(&key_callbacks[key])
                # Build the redis cache key
                cache_key = "#{key.to_s.split("__").first}_#{uniq_id}"
                redis = Redis.new
                # Flush the key by setting it to nil
                redis.set(cache_key, nil)
              rescue NameError => e
                # Nothing was flushed because of an error"
              end
            end
          end

          define_method(:flush_all!) do
            redis = Redis.new

            registered_keys = ClassMethods.key_callbacks.keys
            removable_keys = redis.keys.select do |key|
              registered_keys.include?(key.gsub(/\_[0-9]+/, '').to_sym)
            end

            redis.del(removable_keys) if removable_keys.present?
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
          options = args.last if args.last.is_a?(Hash)

          key_callbacks["#{args.first}__#{self.name.underscore}".to_sym] = args.second
          register_callbacks_for(options) if options.present?
        end

        private

        def register_callbacks_for(options)
          options.each do |callback, callable|
            case callback
            when Symbol
              send(callback, callable) if respond_to?(callback)
            else # It must be Proc or lambda
              send(callback, &callable)
            end
          end
        end
      end
    end
  end
end
