# frozen_string_literal: true

source "https://rubygems.org"

gemspec

# dry-cli with public help hooks (kigster/dry-cli#1 to #4), until they are released.
# DRY_CLI_PATH points at a local checkout instead.
if ENV["DRY_CLI_PATH"]
  gem "dry-cli", path: ENV["DRY_CLI_PATH"]
else
  gem "dry-cli", github: "kigster/dry-cli", branch: "kig/auto-inject-compatibility"
end

group :development, :test do
  gem "coverage-badge"
  gem "irb"
  gem "rake", "~> 13.0"
  gem "rspec", "~> 3.0"
  gem "rspec-its"
  gem "rubocop"
  gem "simplecov"
  gem "yard"
end

# Not a dependency, a collision test. This gem's files sit inside `module Dry`,
# so an unqualified constant resolves there first and a bare `Struct` becomes
# `Dry::Struct` in any host that loads it. Most dry-rb applications do.
gem "dry-struct", require: false
