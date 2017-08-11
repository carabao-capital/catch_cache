# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "catch_cache/version"

Gem::Specification.new do |spec|
  spec.name          = "catch_cache"
  spec.version       = CatchCache::VERSION
  spec.authors       = ["Neil Marion dela Cruz"]
  spec.email         = ["nmfdelacruz@gmail.com"]

  spec.summary       = %q{Catches ruby objects and caches them}
  spec.description   = %q{Catches ruby objects and caches them}
  spec.homepage      = "https://github.com/carabao-capital/catch_cache"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "redis"

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
