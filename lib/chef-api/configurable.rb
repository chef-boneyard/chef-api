module ChefAPI
  #
  # A re-usable class containing configuration information for the {Connection}.
  # See {Defaults} for a list of default values.
  #
  module Configurable
    class << self
      #
      # The list of configurable keys.
      #
      # @return [Array<Symbol>]
      #
      def keys
        @keys ||= [
          :endpoint,
          :flavor,
          :client,
          :key,
          :proxy_address,
          :proxy_password,
          :proxy_port,
          :proxy_username,
          :ssl_pem_file,
          :ssl_verify,
          :user_agent,
          :read_timeout,
        ]
      end
    end

    #
    # Create one attribute getter and setter for each key.
    #
    ChefAPI::Configurable.keys.each do |key|
      attr_accessor key
    end

    #
    # Set the configuration for this config, using a block.
    #
    # @example Configure the API endpoint
    #   ChefAPI.configure do |config|
    #     config.endpoint = "http://www.my-ChefAPI-server.com/ChefAPI"
    #   end
    #
    def configure
      yield self
    end

    #
    # Reset all configuration options to their default values.
    #
    # @example Reset all settings
    #   ChefAPI.reset!
    #
    # @return [self]
    #
    def reset!
      ChefAPI::Configurable.keys.each do |key|
        instance_variable_set(:"@#{key}", Defaults.options[key])
      end
      self
    end
    alias_method :setup, :reset!

    private

    #
    # The list of configurable keys, as an options hash.
    #
    # @return [Hash]
    #
    def options
      map = ChefAPI::Configurable.keys.map do |key|
        [key, instance_variable_get(:"@#{key}")]
      end
      Hash[map]
    end
  end
end
