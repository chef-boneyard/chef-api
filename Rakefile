require "bundler"
require "bundler/gem_helper"

Bundler::GemHelper.install_tasks name: "chef-api"

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new do |t|
  t.rspec_opts = [
    '--color',
    '--format progress',
  ].join(' ')
end

task default: :spec
