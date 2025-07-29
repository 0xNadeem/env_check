# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

# Import custom tasks
Dir.glob("lib/tasks/**/*.rake").each { |r| import r }

# Test task
RSpec::Core::RakeTask.new(:spec)

# Style checking
RuboCop::RakeTask.new

# Security audit task
begin
  require "bundler/audit/task"
  Bundler::Audit::Task.new
rescue LoadError
  namespace :bundle do
    task :audit do
      puts "⚠️  bundler-audit not available"
    end
  end
end

# Documentation task
begin
  require "yard"
  YARD::Rake::YardocTask.new(:doc) do |t|
    t.files = ["lib/**/*.rb"]
    t.options = ["--markup=markdown"]
  end
rescue LoadError
  task :doc do
    puts "⚠️  yard not available"
  end
end

# Quality tasks
namespace :quality do
  desc "Run all quality checks"
  task all: %i[spec rubocop bundle:audit]

  desc "Run tests with coverage"
  task :coverage do
    ENV["COVERAGE"] = "true"
    Rake::Task["spec"].invoke
  end
end

# Default task - run core checks
task default: %i[spec rubocop]

# CI task - comprehensive checking
task ci: %i[quality:all doc]
