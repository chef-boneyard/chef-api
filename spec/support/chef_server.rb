require 'chef_zero/server'

module RSpec
  class ChefServer
    module DSL
      def chef_server
        RSpec::ChefServer
      end
    end

    class << self
      #
      # Delegate all methods to the singleton instance.
      #
      def method_missing(m, *args, &block)
        instance.send(m, *args, &block)
      end

      #
      # RSpec 3 checks +respond_to?+
      #
      def respond_to_missing?(m, include_private = false)
        instance.respond_to?(m, include_private) || super
      end

      #
      # @macro entity
      #   @method create_$1(name, data = {})
      #     Create a new $1 on the Chef Server
      #
      #     @param [String] name
      #       the name of the $1
      #     @param [Hash] data
      #       the list of data to load
      #
      #
      #   @method $1(name)
      #     Find a $1 at the given name
      #
      #     @param [String] name
      #       the name of the $1
      #
      #     @return [$2, nil]
      #
      #
      #   @method $3
      #     The list of $1 on the Chef Server
      #
      #     @return [Array<Hash>]
      #       all the $1 on the Chef Server
      #
      #
      #   @method has_$1?(name)
      #     Determine if the Chef Server has the given $1
      #
      #     @param [String] name
      #       the name of the $1 to find
      #
      #     @return [Boolean]
      #
      def entity(method, key)
        class_eval <<-EOH, __FILE__, __LINE__ + 1
          def create_#{method}(name, data = {})
            # Automatically set the "name" if no explicit one was given
            data[:name] ||= name

            # Convert it to JSON
            data = JSON.fast_generate(data)

            load_data(name, '#{key}', data)
          end

          def #{method}(name)
            data = get('#{key}', name)
            JSON.parse(data)
          rescue ChefZero::DataStore::DataNotFoundError
            nil
          end

          def #{key}
            get('#{key}')
          end

          def has_#{method}?(name)
            !get('#{key}', name).nil?
          rescue ChefZero::DataStore::DataNotFoundError
            false
          end
        EOH
      end
    end

    entity :client,      :clients
    entity :data_bag,    :data
    entity :environment, :environments
    entity :node,        :nodes
    entity :role,        :roles
    entity :user,        :users

    require 'singleton'
    include Singleton

    #
    #
    #
    def initialize
      @server = ChefZero::Server.new({
        # This uses a random port
        port: port,

        # Shut up
        log_level: :fatal,

        # Disable the "old" way - this is actually +multi_tenant: true+
        single_org: false,

        # Don't generate real keys for faster test
        generate_real_keys: false,
      })

      ChefAPI.endpoint = @server.url
      ChefAPI.key      = ChefZero::PRIVATE_KEY
    end

    #
    #
    #
    def start
      @server.start_background(1)
    end

    #
    # Clear all the information in the server. This hook is run after each
    # example group, giving the appearance of an "empty" Chef Server for
    # each test.
    #
    def clear
      @server.clear_data
    end

    #
    # Stop the server (since it might not be running)
    #
    def stop
      @server.stop if @server.running?
    end

    #
    # Get the path to an item in the data store.
    #
    def get(*args)
      if args.size == 1
        @server.data_store.list(args)
      else
        @server.data_store.get(args)
      end
    end

    #
    # Shortcut method for loading data into Chef Zero.
    #
    # @param [String] name
    #   the name or id of the item to load
    # @param [String, Symbol] key
    #   the key to load
    # @param [Hash] data
    #   the data for the object, which will be converted to JSON and uploaded
    #   to the server
    #
    def load_data(name, key, data = {})
      @server.load_data({ key => { name => data } })
    end

    private

      #
      # A randomly assigned, open port for run the Chef Zero server.
      #
      # @return [Fixnum]
      #
      def port
        return @port if @port

        @server = TCPServer.new('127.0.0.1', 0)
        @port   = @server.addr[1].to_i
        @server.close

        return @port
      end
  end
end


RSpec.configure do |config|
  config.before(:suite) { RSpec::ChefServer.start }
  config.after(:each)   { RSpec::ChefServer.clear }
  config.after(:suite)  { RSpec::ChefServer.stop }
end
