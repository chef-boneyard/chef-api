require 'chef-api/version'
require 'pathname'
require 'json'

module ChefAPI
  module Defaults
    # Default API endpoint
    ENDPOINT = 'https://api.opscode.com/'.freeze

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
      # The Chef API configuration
      #
      # @return [Hash]
      def config
        path = config_path
        @config ||= path.exist? ? JSON.parse(path.read) : {}
      end

      #
      # Pathname to configuration file, or a blank Pathname.
      #
      # @return [Pathname] an expanded Pathname or a non-existent Pathname
      def config_path
        if result = chef_api_config_path
          Pathname(result).expand_path
        else
          Pathname('')
        end
      end

      #
      # String representation of path to configuration file
      #
      # @return [String, nil] Path to config file, or nil
      def chef_api_config_path
        ENV['CHEF_API_CONFIG'] || if ENV.key?('HOME')
                                    '~/.chef-api'
                                  else
                                    nil
                                  end
      end

      #
      # The endpoint where the Chef Server lives. This is equivalent to the
      # +chef_server_url+ in Chef terminology. If you are using Enterprise
      # Hosted Chef or Enterprise Chef on premise, this endpoint should include
      # your organization name. For example:
      #
      #     https://api.opscode.com/organizations/bacon
      #
      # If you are running Open Source Chef Server or Chef Zero, this is the
      # full URL to your Chef Server instance, including the server port and
      # FQDN.
      #
      #     https://chef.server.local:4567/
      #
      # @return [String] (default: +https://api.opscode.com/+)
      #
      def endpoint
        ENV['CHEF_API_ENDPOINT'] || config['CHEF_API_ENDPOINT'] || ENDPOINT
      end

      #
      # The flavor of the target Chef Server. There are two possible values:
      #
      #   - enterprise
      #   - open_source
      #
      # "Enterprise" covers both Hosted Chef and Enterprise Chef. "Open Source"
      # covers both Chef Zero and Open Source Chef Server.
      #
      # @return [true, false]
      #
      def flavor
        if ENV['CHEF_API_FLAVOR']
          ENV['CHEF_API_FLAVOR'].to_sym
        elsif config['CHEF_API_FLAVOR']
          config['CHEF_API_FLAVOR']
        else
          endpoint.include?('/organizations') ? :enterprise : :open_source
        end
      end

      #
      # The User Agent header to send along.
      #
      # @return [String]
      #
      def user_agent
        ENV['CHEF_API_USER_AGENT'] || config['CHEF_API_USER_AGENT'] || USER_AGENT
      end

      #
      # The name of the Chef API client. This is the equivalent of
      # +client_name+ in Chef terminology. In most cases, this is your Chef
      # username.
      #
      # @return [String, nil]
      #
      def client
        ENV['CHEF_API_CLIENT'] || config['CHEF_API_CLIENT']
      end

      #
      # The private key to authentication against the Chef Server. This is
      # equivalent to the +client_key+ in Chef terminology. This value can
      # be the client key in plain text or a path to the key on disk.
      #
      # @return [String, nil]
      #
      def key
         ENV['CHEF_API_KEY'] || config['CHEF_API_KEY']
      end
      #
      # The HTTP Proxy server address as a string
      #
      # @return [String, nil]
      #
      def proxy_address
        ENV['CHEF_API_PROXY_ADDRESS'] || config['CHEF_API_PROXY_ADDRESS']
      end

      #
      # The HTTP Proxy user password as a string
      #
      # @return [String, nil]
      #
      def proxy_password
        ENV['CHEF_API_PROXY_PASSWORD'] || config['CHEF_API_PROXY_PASSWORD']
      end

      #
      # The HTTP Proxy server port as a string
      #
      # @return [String, nil]
      #
      def proxy_port
        ENV['CHEF_API_PROXY_PORT'] || config['CHEF_API_PROXY_PORT']
      end

      #
      # The HTTP Proxy server username as a string
      #
      # @return [String, nil]
      #
      def proxy_username
        ENV['CHEF_API_PROXY_USERNAME'] || config['CHEF_API_PROXY_USERNAME']
      end

      #
      # The path to a pem file on disk for use with a custom SSL verification
      #
      # @return [String, nil]
      #
      def ssl_pem_file
        ENV['CHEF_API_SSL_PEM_FILE'] || config['CHEF_API_SSL_PEM_FILE']
      end

      #
      # Verify SSL requests (default: true)
      #
      # @return [true, false]
      #
      def ssl_verify
        if ENV['CHEF_API_SSL_VERIFY'].nil? && config['CHEF_API_SSL_VERIFY'].nil?
          true
        else
          %w[t y].include?(ENV['CHEF_API_SSL_VERIFY'].downcase[0]) || config['CHEF_API_SSL_VERIFY']
        end
      end

      #
      # Network request read timeout in seconds (default: 60)
      #
      # @return [Integer, nil]
      #
      def read_timeout
        timeout_from_env = ENV['CHEF_API_READ_TIMEOUT'] || config['CHEF_API_READ_TIMEOUT']

        Integer(timeout_from_env) unless timeout_from_env.nil?
      end
    end
  end
end
