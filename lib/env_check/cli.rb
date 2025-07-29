# frozen_string_literal: true

require "optparse"
require "fileutils"

module EnvCheck
  # Module for CLI output helpers
  module CLIHelpers
    def success(message)
      puts message unless @options[:quiet]
    end

    def info(message)
      puts message unless @options[:quiet]
    end

    def warning(message)
      puts "⚠️  #{message}" unless @options[:quiet]
    end

    def error(message)
      warn message
    end

    def error_exit(message, code = 1)
      warn "Error: #{message}"
      exit code
    end

    def default_config_path
      Dir.exist?("config") ? "config/env_check.yml" : ".env_check.yml"
    end
  end

  # CLI class for better organization
  class CLI # rubocop:disable Metrics/ClassLength
    include CLIHelpers

    def initialize(args = ARGV)
      @args = args
      @options = {
        config: nil, # Will be auto-discovered if not specified
        quiet: false,
        verbose: false
      }
      @command = nil
    end

    def run
      parse_arguments
      execute_command
    rescue StandardError => e
      error_exit(e.message.to_s)
    end

    private

    def parse_arguments
      parser = create_option_parser
      parser.parse!(@args)
      @command = @args.shift
    end

    def create_option_parser
      OptionParser.new do |opts|
        configure_banner_and_commands(opts)
        configure_options(opts)
      end
    end

    def configure_banner_and_commands(opts)
      opts.banner = "Usage: env_check [options] <command>"
      opts.separator ""
      opts.separator "Commands:"
      opts.separator "  init     Create a new env_check.yml configuration file"
      opts.separator "  check    Validate environment variables against configuration"
      opts.separator "  version  Show version number"
      opts.separator ""
      opts.separator "Options:"
    end

    def configure_options(opts)
      opts.on("-c", "--config PATH",
              "Configuration file path (auto-discovered: .env_check.yml or config/env_check.yml)") do |path|
        @options[:config] = path
      end

      opts.on("-q", "--quiet", "Suppress output (only show errors)") do
        @options[:quiet] = true
      end

      opts.on("-v", "--verbose", "Show detailed output") do
        @options[:verbose] = true
      end

      opts.on("-h", "--help", "Show this help message") do
        puts opts
        exit 0
      end
    end

    def execute_command
      case @command
      when "init"
        init_command
      when "check"
        check_command
      when "version"
        version_command
      when nil
        show_help_and_exit
      else
        error_exit("Unknown command: #{@command}")
      end
    end

    def init_command
      path = @options[:config] || determine_init_path

      begin
        # Create directory if it doesn't exist
        dir = File.dirname(path)
        FileUtils.mkdir_p(dir) unless dir == "."

        if File.exist?(path)
          warning("Configuration file already exists: #{path}")
          return
        end

        create_config_file(path)
        success("Created configuration file: #{path}")

        unless @options[:quiet]
          puts "\nNext steps:"
          puts "1. Edit #{path} to define your required environment variables"
          puts "2. Run 'env_check check' to validate your environment"
        end
      rescue StandardError => e
        error_exit("Failed to create configuration file: #{e.message}")
      end
    end

    def check_command
      config_path = find_config_file

      error_exit("No configuration file found. Run 'env_check init' to create one.") if config_path.nil?

      begin
        result = EnvCheck.verify(config_path)
        display_results(result)
        exit 1 unless result.success?
      rescue StandardError => e
        error_exit("Validation failed: #{e.message}")
      end
    end

    def version_command
      puts EnvCheck::VERSION
    end

    def create_config_file(path)
      File.write(path, config_template)
    end

    def config_template
      <<~YAML
        # EnvCheck Configuration#{Dir.exist?("config") ? " (Rails)" : " (Root Level)"}
        # Configure required and optional environment variables for your application

        # Required environment variables (must be present and non-empty)
        required:
          - DATABASE_URL
          - SECRET_KEY_BASE

        # Optional environment variables with type validation
        optional:
          DEBUG: boolean          # true, false, 1, 0, yes, no (case-insensitive)
          PORT: integer          # numeric values only
          API_URL: url           # must start with http:// or https://
          ADMIN_EMAIL: email     # valid email format
          LOG_LEVEL: string      # any string value
      YAML
    end

    def find_config_file
      return @options[:config] if @options[:config]

      # Check ENV variable first
      return ENV["ENV_CHECK_CONFIG"] if ENV["ENV_CHECK_CONFIG"]

      # Smart discovery
      candidates = [".env_check.yml", "config/env_check.yml"]
      candidates.find { |path| File.exist?(path) }
    end

    def display_results(result) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      # Show valid variables
      result.valid_vars.each do |var|
        success("✅ #{var} is set")
      end

      # Show warnings for optional variables
      result.warnings.each do |warning|
        warning(warning)
      end

      # Show errors for required variables
      result.errors.each do |error|
        error("❌ #{error}")
      end

      # Summary
      if result.success?
        success("\n✅ Environment validation passed!")
        info("Valid variables: #{result.valid_vars.count}")
        info("Warnings: #{result.warnings.count}") if result.warnings.any?
      else
        error("\n❌ Environment validation failed!")
        error("\nErrors:")
        result.errors.each { |err| error("  ❌ #{err}") }

        if result.warnings.any?
          info("\nWarnings:")
          result.warnings.each { |warn| info("  ⚠️  #{warn}") }
        end
      end
    end

    def show_help_and_exit
      puts create_option_parser.help
      exit 1
    end

    # Determine the best path for init command
    def determine_init_path
      default_config_path
    end
  end
end
