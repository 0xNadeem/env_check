# 🔍 EnvCheck

[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%203.0-red.svg)](https://ruby-lang.org)
[![Gem Version](https://img.shields.io/gem/v/env_check.svg?style=flat)](https://rubygems.org/gems/env_check)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

`env_check` is a lightweight Ruby gem to validate and document your environment variables.  
It ensures critical env vars are present and properly formatted before your app boots or deploys.

---

## 🚀 Features

- ✅ Validate required environment variables
- ⚠️ Warn on missing or invalid optional variables
- 🔒 Type checking (boolean, integer, URL, email)
- 📁 YAML-based configuration
- 🔧 Works with any Ruby or Rails app
- 🌱 Supports `.env` file via `dotenv` (optional)
- 🎯 Programmatic API for custom integrations
- 📊 Detailed validation results

---

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'env_check'
```

And then execute:

    $ bundle install

## Ruby and Rails Compatibility

### Ruby Version Support
- **Ruby 3.0+** - Fully supported
- **Ruby 3.1+** - Fully supported  
- **Ruby 3.2+** - Fully supported
- **Ruby 3.3+** - Fully supported
- **Ruby 3.4+** - Fully supported

### Rails Version Support

This gem is framework-agnostic and works with any Ruby application. For Rails applications, it supports:

| Rails Version | Ruby Version | Support Status |
|---------------|--------------|----------------|
| Rails 8.0+    | Ruby 3.2+    | ✅ Supported   |
| Rails 7.2+    | Ruby 3.1+    | ✅ Supported   |
| Rails 7.1+    | Ruby 3.1+    | ✅ Supported   |
| Rails 7.0+    | Ruby 2.7+    | ✅ Supported   |
| Rails 6.1+    | Ruby 2.5+    | ✅ Supported   |
| Rails 6.0+    | Ruby 2.5+    | ✅ Supported   |
| Rails 5.x     | Ruby 2.2+    | ⚠️ Should work but not actively tested |

**Note**: While the gem doesn't directly depend on Rails, it's been designed to work seamlessly in Rails environments and integrates well with Rails' environment variable patterns.

Or install manually:
```bash
gem install env_check
```

---

## ⚡ Quick Start

### 1. Generate Configuration

```bash
env_check init
```

This creates a configuration file using smart defaults:
- **Simple projects**: `.env_check.yml` (root level, pairs with `.env`)  
- **Rails projects**: `config/env_check.yml` (Rails convention)

**Example configuration:**

```yaml
# EnvCheck Configuration
# Required environment variables (must be present and non-empty)
required:
  - DATABASE_URL
  - SECRET_KEY_BASE

# Optional environment variables with type validation
optional:
  DEBUG: boolean          # true, false, 1, 0, yes, no
  PORT: integer          # numeric values only
  API_URL: url           # must start with http:// or https://
  ADMIN_EMAIL: email     # valid email format
```

### 2. Validate Environment

```bash
env_check check
```

Output:
```
✅ DATABASE_URL is set
✅ SECRET_KEY_BASE is set
⚠️  DEBUG should be a boolean, got 'maybe'
❌ Missing required ENV: API_KEY
```

---

## 🛠 Usage

### Command Line Interface

```bash
# Create configuration file
env_check init

# Validate environment variables
env_check check

# Show version
env_check version
```

### Programmatic Usage

```ruby
require 'env_check'

# Basic validation (returns Result object)
result = EnvCheck.verify

if result.success?
  puts "✅ All environment variables are valid!"
  puts "Valid vars: #{result.valid_vars.join(', ')}"
else
  puts "❌ Validation failed!"
  puts "Errors: #{result.errors.join(', ')}"
  puts "Warnings: #{result.warnings.join(', ')}"
end

# Validate with custom config file
result = EnvCheck.verify("path/to/custom.yml")

# Validate with inline configuration
result = EnvCheck.verify_with_config({
  "required" => ["API_KEY", "DATABASE_URL"],
  "optional" => { "DEBUG" => "boolean" }
})

# Legacy method (raises exception on failure)
begin
  EnvCheck.verify!
  puts "✅ Validation passed!"
rescue EnvCheck::Error => e
  puts "❌ #{e.message}"
  exit 1
end
```

### Rails Integration

Add to your `config/application.rb` or initializer:

```ruby
# config/initializers/env_check.rb
EnvCheck.verify! if Rails.env.production?
```

#### Advanced Rails Integration Patterns

**1. Environment-Specific Validation**

```ruby
# config/initializers/env_check.rb
Rails.application.config.after_initialize do
  # Load Rails-specific config
  config_file = Rails.root.join('config', 'env_check.yml')
  
  if config_file.exist?
    result = EnvCheck.verify(config_file)
    unless result.success?
      Rails.logger.error "Environment validation failed: #{result.errors.join(', ')}"
      
      # Only raise in production
      raise EnvCheck::Error, result.errors.join(', ') if Rails.env.production?
    end
  end
end
```

**2. Controller Integration**

```ruby
class ApplicationController < ActionController::Base
  before_action :validate_critical_env_vars, if: -> { Rails.env.production? }
  
  private
  
  def validate_critical_env_vars
    result = EnvCheck.verify_with_config({
      "required" => ["DATABASE_URL", "SECRET_KEY_BASE", "RAILS_MASTER_KEY"]
    })
    
    unless result.success?
      render json: { error: 'Service temporarily unavailable' }, status: 503
    end
  end
end
```

**3. Health Check Endpoint**

```ruby
# config/routes.rb
Rails.application.routes.draw do
  get '/health/env', to: 'health#env_check'
end

# app/controllers/health_controller.rb
class HealthController < ApplicationController
  def env_check
    result = EnvCheck.verify
    
    if result.success?
      render json: { 
        status: 'ok', 
        valid_vars: result.valid_vars.count,
        warnings: result.warnings
      }
    else
      render json: { 
        status: 'error', 
        errors: result.errors 
      }, status: 422
    end
  end
end
```

**4. Environment-Specific Configuration**

Create your config file (`.env_check.yml` or `config/env_check.yml`):

```yaml
default: &default
  optional:
    DEBUG: boolean
    LOG_LEVEL: string

development:
  <<: *default
  required:
    - DATABASE_URL
    - SECRET_KEY_BASE

test:
  <<: *default  
  required:
    - SECRET_KEY_BASE
  optional:
    DATABASE_URL: url

production:
  <<: *default
  required:
    - DATABASE_URL
    - SECRET_KEY_BASE  
    - RAILS_MASTER_KEY
    - REDIS_URL
  optional:
    MEMCACHED_URL: url
    CDN_HOST: url
    SMTP_HOST: string
```

### Rake Integration

```ruby
# In your Rakefile or Rails app
require 'env_check'

# Use the built-in rake task
rake env:check
```

---

## 🔧 Configuration

### Supported Types

- **`boolean`**: `true`, `false`, `1`, `0`, `yes`, `no` (case-insensitive)
- **`integer`**: Positive or negative integers (`123`, `-456`)
- **`url`**: URLs starting with `http://` or `https://`
- **`email`**: Valid email addresses
- **`string`**: Any value (default, no validation)

### Configuration File

```yaml
# config/env_check.yml
required:
  - DATABASE_URL
  - SECRET_KEY_BASE
  - API_KEY

optional:
  # Type validations
  DEBUG: boolean
  PORT: integer
  API_URL: url
  ADMIN_EMAIL: email
  
  # Environment-specific
  RAILS_ENV: string
  RACK_ENV: string
```

### Smart Configuration Discovery

EnvCheck automatically discovers your configuration file using this priority:

1. **`.env_check.yml`** (root level - simple projects, pairs with `.env`)
2. **`config/env_check.yml`** (Rails convention - if `config/` directory exists)
3. **Custom path** via `--config` flag or `ENV_CHECK_CONFIG` environment variable

```bash
# Auto-discovery (checks .env_check.yml, then config/env_check.yml)
env_check check

# Explicit path
env_check check --config custom/path.yml

# Via environment variable
ENV_CHECK_CONFIG=custom/path.yml env_check check

# Via Ruby API
EnvCheck.verify("custom/path.yml")
```

---

## 🧪 Testing

Run the test suite:

```bash
bundle exec rspec
```

Run linting:

```bash
bundle exec rubocop
```

---

## 🤝 Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

Please make sure to update tests and run the linter before submitting.

---

## 📄 License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

---

## 🙏 Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and changes.
