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

In your AR model:

```ruby
In your AR model:

class LoanApplication < ActiveRecord::Base
  include CatchCache::Flush

  belongs_to :lead

  # Everytime the :after_commit AR callback is called,
  # the Redis cache with id "lead_timeline_logs_#{lead.id}"
  # is going to be flushed
  cache_id :lead_timeline_logs, -> { lead.id }
end
```

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
