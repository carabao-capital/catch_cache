require 'active_support/concern'

module CatchCache
  module Flush

    class NoIdGiven < StandardError
      def initialize(msg = ':id parameter must be present')
        super
      end
    end

    extend ActiveSupport::Concern

    AVAILABLE_CALLBACKS = [
      :after_initialize, :after_find, :after_touch, :before_validation, :after_validation,
      :before_save, :around_save, :after_save, :before_create, :around_create,
      :after_create, :before_update, :around_update, :after_update,
      :before_destroy, :around_destroy, :after_destroy, :after_commit, :after_rollback
    ]

    included do
      class_attribute :registry
    end

    module ClassMethods
      def flush_cache(cache_name, *args)
        self.registry ||= []

        entry = register_entry(cache_name, *args)
        register_callbacks_for(entry)
      end

      private

      def register_entry(cache_name, args)
        entry = { cache_name: cache_name, id: args[:id], args: args }
        self.registry.push(entry)

        entry
      end

      def register_callbacks_for(entry)
        callbacks = entry[:args].select do |key, value|
          AVAILABLE_CALLBACKS.include?(key.to_sym)
        end

        return if callbacks.empty?

        # callback is an array having values like
        # [[:after_commit, :flush_by_id], [:after_create, flush_all]]
        callbacks.each do |callback|
          send(callback.first) { send(callback.last, entry) } if respond_to?(callback.first)
        end
      end
    end

    def flush_by_id(entry)
      raise NoIdGiven unless entry[:id]

      id = entry[:id].kind_of?(Proc) ? instance_exec(&entry[:id]) : entry[:id]
      key = "#{entry[:cache_name]}_#{id}"

      redis.del(key)
    end

    def flush_all(entry)
      removable_keys = redis.keys.select do |key|
        key.start_with?(entry[:cache_name].to_s)
      end

      redis.del(removable_keys) unless removable_keys.empty?
    end

    private

    def redis
      @redis ||= Redis.new
    end
  end
end
