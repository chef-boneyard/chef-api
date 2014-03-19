require 'chef_zero/server'

module RSpec
  class ChefServer
    module DSL
      def chef_server
        RSpec::ChefServer
      end
    end

    class << self
      def method_missing(m, *args, &block)
        instance.send(m, *args, &block)
      end
    end

    require 'singleton'
    include Singleton

    #
    #
    #
    def initialize
      @server = ChefZero::Server.new({
        port: port,
        log_level: :fatal,
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
    #
    #
    def load_data(key, id, data = {})
      @server.load_data({ key.to_s => { id => JSON.fast_generate(data) } })
    end

    #
    #
    #
    [
      ['clients', 'client'],
      ['cookbooks', 'cookbook'],
      ['environments', 'environment'],
      ['nodes', 'node'],
      ['roles', 'role'],
      ['users', 'user'],
    ].each do |plural, singular|
      define_method(plural) do
        @server.data_store.list([plural])
      end

      define_method(singular) do |id|
        JSON.parse(@server.data_store.get([plural, id]))
      end

      define_method("create_#{singular}") do |id, data = {}|
        load_data(plural, id, data)
      end

      define_method("has_#{singular}?") do |id|
        send(plural).include?(id)
      end
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
