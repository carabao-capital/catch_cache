# 0.0.5

- Add callback support, like `after_commit: :flush_all!`

# 0.0.4

- Fix catching of errors in `#flush_cache!`

# 0.0.3

- `catch_then_cache` method must be available as an instance method as well

# 0.0.2

- Swallow errors when calling the `key_callbacks` proc in `:flush_cache!`
