require 'json'
require 'pathname'
require 'chef-api/version'

module ChefAPI
  autoload :Boolean,         'chef-api/boolean'
  autoload :Configurable,    'chef-api/configurable'
  autoload :Connection,      'chef-api/connection'
  autoload :Defaults,        'chef-api/defaults'
  autoload :Error,           'chef-api/error'
  autoload :ErrorCollection, 'chef-api/error_collection'
  autoload :Resource,        'chef-api/resource'
  autoload :Schema,          'chef-api/schema'
  autoload :Util,            'chef-api/util'
  autoload :Validator,       'chef-api/validator'

  #
  # @todo Document this and why it's important
  #
  UNSET = Object.new

  class << self
    include ChefAPI::Configurable

    #
    # The source root of the ChefAPI gem. This is useful when requiring files
    # that are relative to the root of the project.
    #
    # @return [Pathname]
    #
    def root
      @root ||= Pathname.new(File.expand_path('../../', __FILE__))
    end

    #
    # API connection object based off the configured options in {Configurable}.
    #
    # @return [ChefAPI::Connection]
    #
    def connection
      unless @connection && @connection.same_options?(options)
        @connection = ChefAPI::Connection.new(options)
      end

      @connection
    end

    #
    # Delegate all methods to the connection object, essentially making the
    # module object behave like a {Connection}.
    #
    def method_missing(m, *args, &block)
      if connection.respond_to?(m)
        connection.send(m, *args, &block)
      else
        super
      end
    end

    #
    # Delegating +respond_to+ to the {Connection}.
    #
    def respond_to_missing?(m, include_private = false)
      connection.respond_to?(m) || super
    end
  end
end

require 'i18n'
I18n.enforce_available_locales = false
I18n.load_path << Dir[ChefAPI.root.join('locales', '*.yml').to_s]

# Load the initial default values
ChefAPI.setup

