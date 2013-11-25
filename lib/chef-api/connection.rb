require 'httpclient'
require 'mixlib/authentication/signedheaderauth'
require 'uri'

module ChefAPI
  #
  # Connection object for the ChefAPI API.
  #
  # @see http://docs.opscode.com/api_chef_server.html
  #
  class Connection
    class << self
      #
      # @private
      #
      # @macro proxy
      #   @method $1
      #     Get a proxied collection for +$1+. The proxy automatically injects
      #     the current connection into the $2, providing a very Rubyesque way
      #     for handling multiple connection objects.
      #
      #     @example Get the $1 from the connection object
      #       connection = ChefAPI::Connection.new('...')
      #       connection.$1 #=> $2 (with the connection object pre-populated)
      #
      #     @return [ChefAPI::Proxy<$2>]
      #       a collection proxy for the $2
      #
      def proxy(name, klass)
        class_eval <<-EOH, __FILE__, __LINE__ + 1
          def #{name}
            @#{name} ||= ChefAPI::Proxy.new(self, #{klass})
          end
        EOH
      end
    end

    include ChefAPI::Configurable

    #
    # Create a new ChefAPI Connection with the given options. Any options
    # given take precedence over the default options.
    #
    # @return [ChefAPI::Connection]
    #
    def initialize(options = {})
      # Use any options given, but fall back to the defaults set on the module
      ChefAPI::Configurable.keys.each do |key|
        value = if options[key].nil?
          ChefAPI.instance_variable_get(:"@#{key}")
        else
          options[key]
        end

        instance_variable_set(:"@#{key}", value)
      end
    end

    #
    # Determine if the given options are the same as ours.
    #
    # @return [Boolean]
    #
    def same_options?(opts)
      opts.hash == options.hash
    end

    #
    # Make a HTTP GET request
    #
    # @param [String] path
    #   the path to get, relative to {Defaults.endpoint}
    #
    def get(path, *args, &block)
      request(:get, path, *args, &block)
    end

    #
    # Make a HTTP POST request
    #
    # @param [String] path
    #   the path to post, relative to {Defaults.endpoint}
    #
    def post(path, *args, &block)
      request(:post, path, *args, &block)
    end

    #
    # Make a HTTP PUT request
    #
    # @param [String] path
    #   the path to put, relative to {Defaults.endpoint}
    #
    def put(path, *args, &block)
      request(:put, path, *args, &block)
    end

    #
    # Make a HTTP PATCH request
    #
    # @param [String] path
    #   the path to patch, relative to {Defaults.endpoint}
    #
    def patch(path, *args, &block)
      request(:patch, path, *args, &block)
    end

    #
    # Make a HTTP DELETE request
    #
    # @param [String] path
    #   the path to delete, relative to {Defaults.endpoint}
    #
    def delete(path, *args, &block)
      request(:delete, path, *args, &block)
    end

    #
    # Make a HTTP HEAD request
    #
    # @param [String] path
    #   the path to head, relative to {Defaults.endpoint}
    #
    def head(path, *args, &block)
      request(:head, path, *args, &block)
    end

    #
    # The actually HTTPClient agent.
    #
    # @return [HTTPClient]
    #
    def agent
      @agent ||= begin
        agent = HTTPClient.new(endpoint)

        agent.agent_name = user_agent

        # Check if authentication was given
        # if username && password
        #   agent.set_auth(endpoint, username, password)

        #   # https://github.com/nahi/httpclient/issues/63#issuecomment-2377919
        #   agent.www_auth.basic_auth.challenge(endpoint)
        # end

        # Check if proxy settings were given
        if proxy
          agent.proxy = proxy
        end

        agent
      end
    end

    #
    # Make an HTTP reequest with the given verb and path.
    #
    # @param [String, Symbol] verb
    #   the HTTP verb to use
    # @param [String] path
    #   the absolute or relative URL to use, expanded relative to {Defaults.endpoint}
    #
    # @return [ChefAPI::RequestWrapper]
    #
    def request(verb, path, *args, &block)
      url = URI.parse(path)

      # Don't merge absolute URLs
      unless url.absolute?
        url = URI.parse(File.join(endpoint, path)).to_s
      end

      # Convert the URL back into a string
      url = url.to_s

      # Add the signing header with Mixlib Auth
      args.push(header: default_headers.merge(signed_header_auth(verb, url)))

      # Make the actual request
      response = agent.send(verb, url, *args, &block)

      case response.status.to_i
      when 200..399
        response
      when 400
        raise 'BadRequest: TODO - make this a real error'
      when 401
        raise 'Unauthorized: TODO - make this a real error'
      when 403
        raise 'Forbidden: TODO - make this a real error'
      when 404
        raise 'NotFound: TODO - make this a real error'
      when 405
        raise Error::HTTPMethodNotAllowed(verb: verb, url: url)
      when 500..600
        raise Error::ServerUnavailable.new(url: url)
      else
        raise Error::ServerUnavailable.new(url: url)
      end
    rescue SocketError, Errno::ECONNREFUSED, EOFError
      raise Error::ServerUnavailable.new(url: url)
    end

    private

    #
    # Parse the given private key. Users can specify the private key as:
    #
    #   - the path to the key on disk
    #   - the raw string key
    #   - an +OpenSSL::PKey::RSA object+
    #
    # Any other implementations are not supported and will likely explode.
    #
    # @todo
    #   Handle errors when the file cannot be read due to insufficient
    #   permissions
    #
    # @param [String, OpenSSL::PKey::RSA] key
    #   the RSA private key
    #
    # @return [OpenSSL::PKey::RSA]
    #   the RSA private key as an OpenSSL object
    #
    def parse_key(key)
      raise 'No private key given' if key.nil?
      return key if key.is_a?(OpenSSL::PKey::RSA)

      if key =~ /(.+)\.pem$/ || File.exists?(key)
        contents = File.read(File.expand_path(key))
      else
        contents = key
      end

      OpenSSL::PKey::RSA.new(contents)
    end

    #
    #
    #
    def signed_header_auth(verb, url)
      url = URI.parse(url)
      private_key = parse_key(key)

      Mixlib::Authentication::SignedHeaderAuth.signing_object(
        :http_method => verb,
        :body        => '',
        :host        => "#{url.host}:#{url.port}",
        :path        => url.path,
        :timestamp   => Time.now.utc.iso8601,
        :user_id     => client,
        :file        => '',
      ).sign(private_key)
    end

    #
    #
    #
    def default_headers
      {
        'Accept'         => 'application/json',
        'Content-Type'   => 'application/json',
        'X-Chef-Version' => '11.4.0',
      }
    end
  end
end
