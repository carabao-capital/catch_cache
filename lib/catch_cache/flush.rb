module CatchCache
  module Flush
    class << self
      def included(klass)
        klass.class_eval do
          extend ClassMethods

          define_method(:flush_cache!) do
            key_callbacks = ClassMethods.key_callbacks

            key_callbacks.keys.select{|key| key.to_s.split("__").last == self.class.base_class.name.underscore }.each do |key|
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

            registered_keys = ClassMethods.key_callbacks.keys.map{|key| key.to_s.split("__").first.to_sym }.uniq
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

        # key_callbacks is hash that stores the a redis key with the proc value that
        # evaluates to a unique id associated with that class. For example:
        # `central_page_loan_plans` key defines the cache for the loading of loan plans
        # index page.
        #
        # An example of a redis key is
        # "central_page_loan_plans_<uniq_id>"
        #
        # Sample args for the cache_id are:
        # cache_id :central_page_loan_plans, after_commit: { flush_cache!: -> { loan_plan.id } }
        # cache_id :central_page_loan_plans, after_commit: :flush_all!
        def cache_id(*args)
          options = args.last if args.last.is_a?(Hash)

          value_args = options.values.first
          proc_value = value_args.is_a?(Hash) ? value_args[:flush_cache!] : value_args
          key_callbacks["#{args.first}__#{self.name.underscore}".to_sym] = proc_value
          register_callbacks_for(options) if options.present?
        end

        private

        def register_callbacks_for(options)
          options.each do |callback, callable|
            case callable
            when Symbol
              send(callback, callable) if respond_to?(callback)
            else # It must be Proc or lambda
              callable = callable.keys.first
              send(callback, callable)
            end
          end
        end
      end
    end
  end
end
