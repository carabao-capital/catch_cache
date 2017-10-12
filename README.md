# CatchCache

An easy way to manage caching and flushing of Ruby objects. Especially useful when you are speeding a very slow API or page.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'catch_cache'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install catch_cache

## Usage

### To cache objects

```ruby
class ServiceWithAVerySlowQuery
  include CatchCache::Cache

  def query
    lead = get_some_lead
    catch_then_cache("lead_timeline_logs_#{lead.id}") do
      # Your very slow query which
      # returns a bunch of Ruby objects
    end
  end
end
```

### :flush_cache!
In your AR model:

```ruby
class LoanApplication < ActiveRecord::Base
  include CatchCache::Flush

  belongs_to :lead

  # Everytime the :after_commit AR callback is called,
  # the Redis cache with id "lead_timeline_logs_#{lead.id}"
  # is going to be flushed

  flush_cache :lead_timeline_logs, after_commit: :flush_by_id, id: -> { lead.id }
  flush_cache :custom_field_form_logs, after_commit: :flush_by_id, id: 2
end
```

### :flush_all!
Use `:flush_all` to clear the cache for all the keys with the suffix of cache key.

In your AR model:

```ruby
class AdminUser < ActiveRecord::Base
  include CatchCache::Flush

  # Everytime the :after_commit AR callback is called,
  # all the Redis caches with suffix "lead_timeline_logs"
  # are going to be flushed

  flush_cache :lead_timeline_logs, after_commit: :flush_all
end
```

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
