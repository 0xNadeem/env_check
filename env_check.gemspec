# frozen_string_literal: true

require_relative "lib/env_check/version"

Gem::Specification.new do |spec|
  spec.name          = "env_check"
  spec.version       = EnvCheck::VERSION
  spec.authors       = ["Mohammad Nadeem"]
  spec.email         = ["nadeemrails91@gmail.com"]

  spec.summary       = "Validate and document required environment variables for your Ruby/Rails app."
  spec.description   = "EnvCheck is a lightweight Ruby gem that ensures your required and optional " \
                       "environment variables are present and valid before your app boots. Features smart " \
                       "config discovery (.env_check.yml or config/env_check.yml), comprehensive type validation " \
                       "with 9 built-in validators, .env loading with dotenv, and professional CLI tools. " \
                       "Framework-agnostic design works with Rails 7.1+ through Rails 8.0+, Ruby 3.0+."
  spec.homepage      = "https://github.com/0xNadeem/env_check"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"]     = spec.homepage
  spec.metadata["source_code_uri"]  = "https://github.com/0xNadeem/env_check"
  spec.metadata["changelog_uri"]    = "https://github.com/0xNadeem/env_check/blob/main/CHANGELOG.md"
  spec.metadata["documentation_uri"] = "https://github.com/0xNadeem/env_check/blob/main/README.md"
  spec.metadata["bug_tracker_uri"]  = "https://github.com/0xNadeem/env_check/issues"
  spec.metadata["wiki_uri"]         = "https://github.com/0xNadeem/env_check/wiki"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      f.match?(%r{^(test|spec|features)/}) ||
        f.match?(/^\.git/) ||
        f.match?(%r{^\.github/}) ||
        f.match?(%r{^\.idea/}) ||
        f.match?(%r{^\.vscode/}) ||
        f.start_with?("Gemfile") ||
        f == "Rakefile" ||
        f == File.basename(__FILE__)
    end
  end

  spec.bindir        = "bin"
  spec.executables   = ["env_check"]
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "dotenv", "~> 2.7"

  # Development dependencies
  spec.add_development_dependency "benchmark", "~> 0.3"
  spec.add_development_dependency "bundler-audit", "~> 0.9"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "rubocop", "~> 1.63"
  spec.add_development_dependency "rubocop-rake", "~> 0.6"
  spec.add_development_dependency "rubocop-rspec", "~> 2.29"
  spec.add_development_dependency "simplecov", "~> 0.22"
  spec.add_development_dependency "yard", "~> 0.9"

  spec.metadata["rubygems_mfa_required"] = "true"
end
