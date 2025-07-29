# frozen_string_literal: true

# lib/tasks/env_check.rake

require_relative "../../lib/env_check"
if File.exist?(".env")
  require "dotenv"
  Dotenv.load
end

namespace :env do
  desc "Check environment variable configuration"
  task :check do
    EnvCheck.verify!
  end
end
