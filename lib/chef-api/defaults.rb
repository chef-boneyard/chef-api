require 'chef-api/version'

module ChefAPI
  module Defaults
    # Default API endpoint
    ENDPOINT = 'http://localhost:4000/'.freeze

    # Default User Agent header string
    USER_AGENT = "ChefAPI Ruby Gem #{ChefAPI::VERSION}".freeze

    class << self
      #
      # The list of calculated default options for the configuration.
      #
      # @return [Hash]
      #
      def options
        Hash[Configurable.keys.map { |key| [key, send(key)] }]
      end

      #
      # The endpoint where the Chef Server lives. This is equivalent to the
      # +chef_server_url+ in Chef terminology. If you are using Enterprise
      # Hosted Chef or Enterprise Chef on premise, this endpoint includes your
      # organization name, such as:
      #
      #     https://api.opscode.com/organizations/NAME
      #
      # If you are running Open Source Chef Server or Chef Zero, this is just
      # the URL to your Chef Server instance, such as:
      #
      #     http://chef.example.com/
      #
      # @return [String]
      #
      def endpoint
        ENV['CHEFAPI_ENDPOINT'] || ENDPOINT
      end

      #
      # The User Agent header to send along.
      #
      # @return [String]
      #
      def user_agent
        ENV['CHEFAPI_USER_AGENT'] || USER_AGENT
      end

      #
      # The name of the Chef API client. This is the equivalent of
      # +client_name+ in Chef terminology. In most cases, this is your Chef
      # username.
      #
      # @return [String, nil]
      #
      def client
        ENV['CHEFAPI_CLIENT']
      end

      #
      # The private key to authentication against the Chef Server. This is
      # equivalent to the +client_key+ in Chef terminology. This value can
      # be the client key in plain text or a path to the key on disk.
      #
      # @return [String, nil]
      #
      def key
        ENV['CHEFAPI_KEY']
      end

      #
      # The HTTP Proxy information as a string
      #
      # @return [String, nil]
      #
      def proxy
        ENV['CHEFAPI_PROXY']
      end
    end
  end
end
