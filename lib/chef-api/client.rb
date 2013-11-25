require 'faraday'
require 'faraday_middleware'

module ChefAPI
  class Client
    # @return [String]
    #   the endpoint for the Chef Server, equivalent to +chef_server_url+
    #   in Chef terminology
    attr_accessor :endpoint

    # @return [String]
    #   the name of the Chef API client, equivalent to +client_name+ in Chef
    #   terminology
    attr_accessor :client

    # @return [String]
    #   the client key, as a String, equivalent to +client_key+ in Chef
    #   terminology
    attr_accessor :key

    # @return [String, nil]
    #   the Chef organization (not applicable on Open Source Chef Server)
    attr_accessor :organization

    #
    #
    #
    def initialize(endpoint, client, key)
      @endpoint = endpoint
      @client   = client
      @key      = key
    end

    def clients
      @clients ||= connection.get('clients')
    end

    def cookbooks
      @cookbooks ||= connection.get('cookbooks')
    end

    def nodes
      @nodes ||= connection.get('nodes')
    end

    private

      #
      #
      #
      def connection
        @connection ||= Faraday.new(endpoint) do |connection|
          # Encode request bodies as JSON
          connection.request :json

          # Retry everything 2x, waiting 1s between retries
          # connection.request :retry, max: 2, interval: 1

          # Add Mixlib authentication headers
          connection.use ChefAPI::Middleware::Authentication, client, key

          # Decode responses as JSON if the Content-Type is json
          connection.response :json
          connection.response :json_fix

          # Allow up to 3 redirects
          connection.response :follow_redirects, limit: 3

          # Log all requests and responses (useful for development)
          connection.response :logger if ENV['DEBUG']

          # Raise errors on 40x and 50x responses
          connection.response :raise_error

          # Use the default adapter (Net::HTTP)
          connection.adapter :net_http

          # Set the User-Agent header for logging purposes
          connection.headers[:user_agent] = ChefAPI::USER_AGENT

          # Set some options, such as timeouts
          connection.options[:timeout]      = 10
          connection.options[:open_timeout] = 10
        end
      end

  end
end
