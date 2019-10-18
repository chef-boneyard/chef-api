require "bundler"
require "bundler/gem_helper"

Bundler::GemHelper.install_tasks name: "chef-api"

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new do |t|
  t.rspec_opts = [
    "--color",
    "--format progress",
  ].join(" ")
end

begin
  require "chefstyle"
  require "rubocop/rake_task"
  desc "Run Chefstyle tests"
  RuboCop::RakeTask.new(:style) do |task|
    task.options += ["--display-cop-names", "--no-color"]
  end
rescue LoadError
  puts "chefstyle gem is not installed. bundle install first to make sure all dependencies are installed."
end

begin
  require "yard"
  YARD::Rake::YardocTask.new(:docs)
rescue LoadError
  puts "yard is not available. bundle install first to make sure all dependencies are installed."
end

task default: %i{style spec}
