# frozen_string_literal: true

module EnvCheck
  # Custom validator classes for different environment variable types
  module Validators
    class Base
      def self.valid?(value)
        raise NotImplementedError, "Subclasses must implement #valid?"
      end
    end

    class Boolean < Base
      VALID_VALUES = %w[true false 1 0 yes no on off].freeze

      def self.valid?(value)
        return false if value.nil? || value.strip.empty?

        VALID_VALUES.include?(value.strip.downcase)
      end
    end

    class Integer < Base
      def self.valid?(value)
        return false if value.nil? || value.strip.empty?

        value.strip.match?(/\A-?\d+\z/)
      end
    end

    class Float < Base
      def self.valid?(value)
        return false if value.nil? || value.strip.empty?

        begin
          Float(value.strip)
          true
        rescue ArgumentError
          false
        end
      end
    end

    class Url < Base
      def self.valid?(value)
        return false if value.nil? || value.strip.empty?

        value.strip.match?(%r{\Ahttps?://\S+\z})
      end
    end

    class Email < Base
      def self.valid?(value)
        return false if value.nil? || value.strip.empty?

        value.strip.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
      end
    end

    class Path < Base
      def self.valid?(value)
        return false if value.nil? || value.strip.empty?

        # Basic path validation - should not contain null bytes and be reasonable length
        path = value.strip
        !path.include?("\0") && path.length.positive? && path.length < 1000
      end
    end

    class Port < Base
      def self.valid?(value)
        return false if value.nil? || value.strip.empty?

        port = value.strip.to_i
        port.positive? && port <= 65_535
      end
    end

    class Enum < Base
      def self.valid?(value, allowed_values = [])
        return false if value.nil? || value.strip.empty?
        return false if allowed_values.empty?

        allowed_values.include?(value.strip)
      end
    end

    class JsonString < Base
      def self.valid?(value)
        return false if value.nil? || value.strip.empty?

        begin
          require "json"
          JSON.parse(value.strip)
          true
        rescue JSON::ParserError
          false
        end
      end
    end
  end
end
