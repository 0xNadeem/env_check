# frozen_string_literal: true

# lib/env_check/rake_task.rb
require "rake"
require_relative "../env_check"

namespace :env do
  desc "Check environment variable configuration"
  task :check do
    EnvCheck.verify!
  end
end
