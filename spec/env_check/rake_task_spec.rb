# frozen_string_literal: true

# spec/env_check/rake_task_spec.rb

require "spec_helper"
require "rake"

RSpec.describe "env:check Rake task" do
  before do
    Rake.application = Rake::Application.new
    Rake.application.rake_require("tasks/env_check", [File.expand_path("../../lib", __dir__)])
    Rake::Task.define_task(:environment) # Needed for Rails-style apps
  end

  it "runs without crashing" do
    expect { Rake::Task["env:check"].invoke }.not_to raise_error
  end
end
