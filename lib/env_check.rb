# frozen_string_literal: true

# EnvCheck is a Ruby gem to validate presence and format of environment variables
# before your application boots or runs. Supports YAML configuration and type checking.
#
# Features:
# - Checks for required and optional environment variables
# - Validates types: boolean, integer, url, string (default)
# - Supports config via `ENV["ENV_CHECK_CONFIG"]`
# - Auto-loads `.env` file if present

require "yaml"

# Load version and rake task
require_relative "env_check/version"
require_relative "env_check/config"
require_relative "env_check/validators"
require_relative "env_check/rake_task" if defined?(Rake)

# Load .env automatically (if present)
if File.exist?(".env")
  begin
    require "dotenv"
    Dotenv.load
  rescue LoadError
    warn "🔍 dotenv not installed — skipping .env loading"
  end
end

# EnvCheck provides validation for environment variables using a YAML config file.
module EnvCheck
  class Error < StandardError; end

  class Result
    attr_reader :errors, :warnings, :valid_vars

    def initialize
      @errors = []
      @warnings = []
      @valid_vars = []
    end

    def add_error(message)
      @errors << message
    end

    def add_warning(message)
      @warnings << message
    end

    def add_valid(var_name)
      @valid_vars << var_name
    end

    def success?
      @errors.empty?
    end

    def display_results
      @valid_vars.each { |var| puts "✅ #{var} is set" }
      @errors.each { |error| puts "❌ #{error}" }
      @warnings.each { |warning| puts "⚠️  #{warning}" }
    end
  end

  # Verifies environment variables against a YAML config file.
  #
  # @param config_path [String] path to the config file (auto-discovered: .env_check.yml or config/env_check.yml)
  # @param environment [String] environment to use for environment-specific configuration
  # @return [Result] validation result object
  def self.verify(config_path = nil, environment = nil)
    config = Config.new(config_path, environment)
    result = Result.new

    unless config.valid?
      puts "⚠️  Config file not found: #{config.config_path}"
      return result
    end

    validate_required_vars(config.required_vars, result)
    validate_optional_vars(config.optional_vars, result)

    result.display_results
    result
  end

  # Verify with inline configuration (useful for testing or programmatic use)
  def self.verify_with_config(config_hash)
    config = Config.from_hash(config_hash)
    result = Result.new

    validate_required_vars(config.required_vars, result)
    validate_optional_vars(config.optional_vars, result)

    result.display_results
    result
  end

  # Legacy method for backward compatibility - raises on error
  def self.verify!(config_path = nil, environment = nil)
    result = verify(config_path, environment)
    raise Error, "Environment validation failed" unless result.success?

    result
  end

  private_class_method def self.validate_required_vars(required_vars, result)
    required_vars.each do |var|
      if ENV[var].nil? || ENV[var].strip.empty?
        result.add_error("Missing required ENV: #{var}")
      else
        result.add_valid(var)
      end
    end
  end

  private_class_method def self.validate_optional_vars(optional_vars, result)
    optional_vars.each do |var, type|
      value = ENV.fetch(var, nil)
      next unless value

      if valid_type?(value, type)
        result.add_valid(var)
      else
        result.add_warning("#{var} should be a #{type}, got '#{value}'")
      end
    end
  end

  private_class_method def self.valid_type?(value, type)
    case type.to_s.downcase
    when "boolean"
      Validators::Boolean.valid?(value)
    when "integer"
      Validators::Integer.valid?(value)
    when "float"
      Validators::Float.valid?(value)
    when "url"
      Validators::Url.valid?(value)
    when "email"
      Validators::Email.valid?(value)
    when "path"
      Validators::Path.valid?(value)
    when "port"
      Validators::Port.valid?(value)
    when "json"
      Validators::JsonString.valid?(value)
    else
      true # Default to valid for unknown types
    end
  end
end
