require 'bundler/gem_tasks'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new do |t|
  t.rspec_opts = [
    '--color',
    '--format progress',
  ].join(' ')
end

task default: :spec
