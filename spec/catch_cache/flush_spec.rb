require 'spec_helper'

class Record
  include ActiveSupport::Callbacks

  define_callbacks :commit

  class << self
    def after_commit(&block)
      set_callback :commit, :after, ->() { instance_exec(&block) }
    end
  end

  def save
    run_callbacks :commit
  end
end

class FlushUsingId < Record
  include CatchCache::Flush

  flush_cache :foo_cache, after_commit: :flush_by_id, id: 1
  flush_cache :bar_cache, after_commit: :flush_by_id, id: -> { 2 }
end

class FlushUsingIdExceptId < Record
  include CatchCache::Flush

  flush_cache :foo_cache, after_commit: :flush_by_id
end

class FlushAll < Record
  include CatchCache::Flush

  flush_cache :foo_cache, after_commit: :flush_all
end

RSpec.describe CatchCache::Flush do
  let(:redis) { Redis.new }
  let(:redis_keys) { redis.keys }

  context '.flush_cache' do
    it 'registers entry' do
      expect(FlushUsingId.registry.count).to eq(2)

      expect(FlushUsingId.registry.first) \
        .to eq({ cache_name: :foo_cache, id: 1, args: { after_commit: :flush_by_id, id: 1 } })
    end

    it 'registers callback for entries' do
      expect(FlushUsingId._commit_callbacks.count).to eq(2)
    end
  end

  context '#flush_by_id' do
    it 'removes entry from redis for the given cache key and ID' do
      redis.set('foo_cache_1', 'Foo')
      redis.set('bar_cache_2', 'Bar')

      FlushUsingId.new.save

      expect(redis_keys & ['foo_cache_1', 'bar_cache_2']).to be_empty
    end

    it 'does no op when key is not found' do
      redis.set('foo_cache_0', 'Foo')

      FlushUsingId.new.save

      expect(redis_keys.include?('foo_cache_0')).to eq(true)
    end

    it 'raises exception when no ID is given' do
      expect { FlushUsingIdExceptId.new.save } \
        .to raise_error(CatchCache::Flush::NoIdGiven)
    end
  end

  context '#flush_all' do
    it 'removes all keys registerd to a cache name' do
      redis.set('foo_cache_1', 'Foo')

      FlushAll.new.save

      expect(redis_keys.include?('foo_cache_1')).to eq(false)
    end

    it 'does no op in case key is not found' do
      redis.set('bar_cache_2', 'Foo')

      FlushAll.new.save

      expect(redis_keys.include?('bar_cache_2')).to eq(true)
    end
  end
end
