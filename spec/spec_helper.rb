require 'chef-api'

RSpec.configure do |config|
  # Chef Server
  require 'support/chef_server'
  config.include(RSpec::ChefServer::DSL)

  # Shared Examples
  Dir[ChefAPI.root.join('spec/support/shared/**/*.rb')].each { |file| require file }

  # Basic configuraiton
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run(:focus)

  #
  config.before(:each) do
    Logify.level = :fatal
  end

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'
end
