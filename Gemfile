# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in env_check.gemspec
gemspec

group :development do
  # Additional development tools not needed by gem users
  gem "bundler-audit", "~> 0.9"  # Security vulnerability checking
  gem "yard", "~> 0.9"           # Documentation generation
end

group :test do
  # Test-specific gems
  gem "simplecov", "~> 0.22", require: false # Code coverage
end
