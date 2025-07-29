# frozen_string_literal: true

module EnvCheck
  # Configuration management for EnvCheck
  class Config
    # Priority order for auto-discovery
    DEFAULT_PATHS = [
      ".env_check.yml",        # Root level (simple/tool-focused projects)
      "config/env_check.yml"   # Rails convention (if config/ exists)
    ].freeze

    attr_reader :required_vars, :optional_vars, :config_path

    def initialize(config_path = nil, environment = nil)
      @config_path = config_path || ENV["ENV_CHECK_CONFIG"] || discover_config_path
      @environment = environment || ENV["RAILS_ENV"] || ENV["RACK_ENV"] || "development"
      load_config
    end

    def self.from_hash(config_hash)
      instance = allocate
      instance.instance_variable_set(:@required_vars, config_hash["required"] || [])
      instance.instance_variable_set(:@optional_vars,
                                     instance.send(:normalize_optional_vars, config_hash["optional"] || {}))
      instance.instance_variable_set(:@config_path, "inline")
      instance
    end

    def valid?
      File.exist?(@config_path)
    end

    # Discover config file using priority order
    def self.discover_config_path
      DEFAULT_PATHS.find { |path| File.exist?(path) } || DEFAULT_PATHS.first
    end

    private

    def discover_config_path
      self.class.discover_config_path
    end

    def load_config
      if File.exist?(@config_path)
        config = YAML.load_file(@config_path)

        # Support environment-specific configurations
        env_config = config[@environment] || config

        @required_vars = env_config["required"] || []

        # Handle optional vars - support both hash and array formats
        optional_config = env_config["optional"] || {}
        @optional_vars = normalize_optional_vars(optional_config)
      else
        @required_vars = []
        @optional_vars = {}
      end
    end

    # Normalize optional vars to support both hash and array formats
    # Hash format: { "VAR" => "type" }
    # Array format: [{ "VAR" => "type" }, "SIMPLE_VAR"]
    def normalize_optional_vars(optional_config)
      case optional_config
      when Hash
        optional_config
      when Array
        result = {}
        optional_config.each do |item|
          case item
          when Hash
            result.merge!(item)
          when String
            result[item] = nil
          end
        end
        result
      else
        {}
      end
    end
  end
end
