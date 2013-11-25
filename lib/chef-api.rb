require 'chef-api/version'

module ChefAPI
  USER_AGENT = "ChefAPI #{ChefAPI::VERSION}"

  autoload :Boolean, 'chef-api/boolean'
  autoload :Client,  'chef-api/client'
  autoload :Schema,  'chef-api/schema'

  module Resource
    autoload :Base,        'chef-api/resources/base'
    autoload :Client,      'chef-api/resources/client'
    autoload :Cookbook,    'chef-api/resources/cookbook'
    autoload :Environment, 'chef-api/resources/environment'
    autoload :Node,        'chef-api/resources/node'
    autoload :Role,        'chef-api/resources/role'
  end

  module Middleware
    autoload :Authentication, 'chef-api/middlewares/authentication'
  end

  class ChefAPIError < StandardError; end

  extend self

  #
  # Initialize a new connection to a Chef Server with the given options.
  #
  # @example Initializing a connection to a Chef Server
  #   ChefAPI.connect(endpoint: 'https://api.opscode.com', client: 'sethvargo', key: 'AADKA...')
  #
  #
  #
  # @param [Hash] options
  #   a list of configuration options to pass to the connection
  #
  # @return [ChefAPI::Connection]
  #
  def connect(options = {})

  end

  def connect!(options = {})

  end
end
