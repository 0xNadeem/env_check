# frozen_string_literal: true

RSpec.describe EnvCheck do
  let(:config_content) do
    {
      "required" => %w[DATABASE_URL SECRET_KEY],
      "optional" => {
        "DEBUG" => "boolean",
        "PORT" => "integer",
        "API_URL" => "url"
      }
    }
  end

  let(:env_specific_config) do
    {
      "development" => {
        "required" => %w[DATABASE_URL],
        "optional" => {
          "DEBUG" => "boolean"
        }
      },
      "production" => {
        "required" => %w[DATABASE_URL SECRET_KEY RAILS_MASTER_KEY],
        "optional" => {
          "REDIS_URL" => "url"
        }
      }
    }
  end

  before do
    allow(File).to receive(:exist?).and_return(true)
    allow(YAML).to receive(:load_file).and_return(config_content)
    allow($stdout).to receive(:puts) # Suppress output during tests
  end

  describe ".verify" do
    context "when all required vars are present" do
      before do
        ENV["DATABASE_URL"] = "postgres://localhost/test"
        ENV["SECRET_KEY"] = "secret123"
      end

      after do
        ENV.delete("DATABASE_URL")
        ENV.delete("SECRET_KEY")
      end

      it "returns successful result" do
        result = EnvCheck.verify
        expect(result.success?).to be true
        expect(result.valid_vars).to include("DATABASE_URL", "SECRET_KEY")
      end
    end

    context "when required vars are missing" do
      before do
        ENV.delete("DATABASE_URL")
        ENV.delete("SECRET_KEY")
      end

      it "returns failed result with errors" do
        result = EnvCheck.verify
        expect(result.success?).to be false
        expect(result.errors).to include("Missing required ENV: DATABASE_URL")
        expect(result.errors).to include("Missing required ENV: SECRET_KEY")
      end
    end

    context "with optional variables" do
      before do
        ENV["DATABASE_URL"] = "postgres://localhost/test"
        ENV["SECRET_KEY"] = "secret123"
      end

      after do
        ENV.delete("DEBUG")
        ENV.delete("PORT")
        ENV.delete("API_URL")
        ENV.delete("RATE")
        ENV.delete("SERVER_PORT")
        ENV.delete("CONFIG_JSON")
      end

      it "validates boolean types correctly" do
        ENV["DEBUG"] = "true"
        result = EnvCheck.verify
        expect(result.valid_vars).to include("DEBUG")
        expect(result.warnings).to be_empty
      end

      it "warns about invalid boolean values" do
        ENV["DEBUG"] = "maybe"
        result = EnvCheck.verify
        expect(result.warnings).to include("DEBUG should be a boolean, got 'maybe'")
      end

      it "validates integer types correctly" do
        ENV["PORT"] = "3000"
        result = EnvCheck.verify
        expect(result.valid_vars).to include("PORT")
      end

      it "warns about invalid integer values" do
        ENV["PORT"] = "abc"
        result = EnvCheck.verify
        expect(result.warnings).to include("PORT should be a integer, got 'abc'")
      end

      it "validates URL types correctly" do
        ENV["API_URL"] = "https://api.example.com"
        result = EnvCheck.verify
        expect(result.valid_vars).to include("API_URL")
      end

      it "warns about invalid URL values" do
        ENV["API_URL"] = "not-a-url"
        result = EnvCheck.verify
        expect(result.warnings).to include("API_URL should be a url, got 'not-a-url'")
      end

      it "validates float types correctly" do
        allow(YAML).to receive(:load_file).and_return({
                                                        "required" => [],
                                                        "optional" => { "RATE" => "float" }
                                                      })
        ENV["RATE"] = "3.14"
        result = EnvCheck.verify
        expect(result.valid_vars).to include("RATE")
      end

      it "validates port types correctly" do
        allow(YAML).to receive(:load_file).and_return({
                                                        "required" => [],
                                                        "optional" => { "SERVER_PORT" => "port" }
                                                      })
        ENV["SERVER_PORT"] = "8080"
        result = EnvCheck.verify
        expect(result.valid_vars).to include("SERVER_PORT")
      end

      it "validates JSON types correctly" do
        allow(YAML).to receive(:load_file).and_return({
                                                        "required" => [],
                                                        "optional" => { "CONFIG_JSON" => "json" }
                                                      })
        ENV["CONFIG_JSON"] = '{"key": "value"}'
        result = EnvCheck.verify
        expect(result.valid_vars).to include("CONFIG_JSON")
      end
    end

    context "with array format optional variables" do
      before do
        allow(File).to receive(:exist?).with(".env_check.yml").and_return(true)
        allow(YAML).to receive(:load_file).with(".env_check.yml").and_return(
          "required" => ["DATABASE_URL"],
          "optional" => [
            { "DEBUG" => "boolean" },
            "SIMPLE_VAR"
          ]
        )
        ENV["DATABASE_URL"] = "postgres://localhost/test"
      end

      after do
        ENV.delete("DATABASE_URL")
        ENV.delete("DEBUG")
        ENV.delete("SIMPLE_VAR")
      end

      it "validates typed variables correctly" do
        ENV["DEBUG"] = "true"
        result = EnvCheck.verify
        expect(result.success?).to be true
        expect(result.valid_vars).to include("DEBUG")
      end

      it "handles simple variables correctly" do
        ENV["SIMPLE_VAR"] = "any_value"
        result = EnvCheck.verify
        expect(result.success?).to be true
        expect(result.valid_vars).to include("SIMPLE_VAR")
      end
    end

    context "with environment-specific configuration" do
      before do
        allow(YAML).to receive(:load_file).and_return(env_specific_config)
      end

      context "when testing development environment" do
        before do
          ENV["DATABASE_URL"] = "postgres://localhost/test"
          ENV["DEBUG"] = "true"
        end

        after do
          ENV.delete("DATABASE_URL")
          ENV.delete("DEBUG")
        end

        it "uses development config section" do
          result = EnvCheck.verify(nil, "development")
          expect(result.success?).to be true
          expect(result.valid_vars).to include("DATABASE_URL", "DEBUG")
        end
      end

      context "when testing production environment" do
        before do
          ENV["DATABASE_URL"] = "postgres://localhost/prod"
          ENV["SECRET_KEY"] = "secret123"
          ENV["RAILS_MASTER_KEY"] = "master123"
        end

        after do
          ENV.delete("DATABASE_URL")
          ENV.delete("SECRET_KEY")
          ENV.delete("RAILS_MASTER_KEY")
        end

        it "uses production config section" do
          result = EnvCheck.verify(nil, "production")
          expect(result.success?).to be true
          expect(result.valid_vars).to include("DATABASE_URL", "SECRET_KEY", "RAILS_MASTER_KEY")
        end
      end

      context "when environment section doesn't exist" do
        it "falls back to empty config" do
          result = EnvCheck.verify(nil, "nonexistent")
          expect(result.success?).to be true # No required vars in empty config, so should succeed
        end
      end
    end

    context "when config file doesn't exist" do
      before do
        allow(File).to receive(:exist?).and_return(false)
      end

      it "returns empty result and prints warning" do
        expect { EnvCheck.verify }.to output(/Config file not found/).to_stdout
        result = EnvCheck.verify
        expect(result.success?).to be true # No errors, just missing config
      end
    end
  end

  describe ".verify!" do
    context "when validation passes" do
      before do
        ENV["DATABASE_URL"] = "postgres://localhost/test"
        ENV["SECRET_KEY"] = "secret123"
      end

      after do
        ENV.delete("DATABASE_URL")
        ENV.delete("SECRET_KEY")
      end

      it "returns result without raising" do
        expect { EnvCheck.verify! }.not_to raise_error
      end
    end

    context "when validation fails" do
      before do
        ENV.delete("DATABASE_URL")
        ENV.delete("SECRET_KEY")
      end

      it "raises EnvCheck::Error" do
        expect { EnvCheck.verify! }.to raise_error(EnvCheck::Error, "Environment validation failed")
      end
    end
  end

  it "has a version number" do
    expect(EnvCheck::VERSION).not_to be nil
  end
end
