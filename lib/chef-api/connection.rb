require 'net/http'
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
    # @param [Hash] params
    #   the list of key-value parameters
    #
    def get(path, params = {})
      uri = urify(path)
      uri.query = URI.encode_www_form(params) unless params.empty?

      request = Net::HTTP::Get.new(uri)

      perform(request)
    end

    #
    # Make a HTTP POST request
    #
    # @param [String] path
    #   the path to post, relative to {Defaults.endpoint}
    # @param [String] body
    #   the body of the request
    #
    def post(path, body)
      uri = urify(path)

      request = Net::HTTP::Post.new(uri)
      request.body = body

      perform(request)
    end

    #
    # Make a HTTP PUT request
    #
    # @param [String] path
    #   the path to put, relative to {Defaults.endpoint}
    # @param [String] body
    #   the body of the request
    #
    def put(path, body)
      uri = urify(path)

      request = Net::HTTP::Put.new(uri)
      request.body = body

      perform(request)
    end

    #
    # Make a HTTP PATCH request
    #
    # @param [String] path
    #   the path to patch, relative to {Defaults.endpoint}
    # @param [String] body
    #   the body of the request
    #
    def patch(path, body)
      uri = urify(path)

      request = Net::HTTP::Patch.new(uri)
      request.body = body

      perform(request)
    end

    #
    # Make a HTTP DELETE request
    #
    # @param [String] path
    #   the path to delete, relative to {Defaults.endpoint}
    #
    def delete(path)
      uri = urify(path)

      request = Net::HTTP::Delete.new(uri)
      perform(request)
    end

    #
    # Make a HTTP HEAD request
    #
    # @param [String] path
    #   the path to head, relative to {Defaults.endpoint}
    #
    def head(path)
      uri = urify(path)

      request = Net::HTTP::Head.new(uri)
      perform(request)
    end

    #
    # Perform the HTTP request, handling responses.
    #
    # @param [Net::HTTP::Request] request
    #   the HTTP request object to make the request with
    #
    # @return [String]
    #
    def perform(request)
      add_request_headers(request)
      url = request.uri.to_s

      response = http.request(request)

      puts
      puts response.body
      puts

      case response.code.to_i
      when 200..399
        parse_response(response)
      when 400
        raise Error::HTTPBadRequest.new(url: url)
      when 401
        raise Error::HTTPUnauthorizedRequest.new(url: url)
      when 403
        raise Error::HTTPForbiddenRequest.new(url: url)
      when 404
        raise Error::HTTPNotFound.new(url: url)
      when 405
        raise Error::HTTPMethodNotAllowed.new(verb: verb, url: url)
      when 500..600
        raise Error::HTTPServerUnavailable.new(url: url)
      else
        raise Error::HTTPServerUnavailable.new(url: url)
      end
    rescue SocketError, Errno::ECONNREFUSED, EOFError
      raise Error::HTTPServerUnavailable.new(url: url)
    end

    private

    #
    # The HTTP request object.
    #
    # @return [Net::HTTP]
    #
    def http
      return @http if @http

      uri = URI.parse(endpoint)
      @http = Net::HTTP.new(uri.host, uri.port)
      @http.use_ssl = true if uri.scheme == 'https'
      @http
    end

    #
    # Helper method to merge the given URL attribute with the endpoint.
    #
    # @param [String, URI] path
    #   the path to make the URI from
    #
    # @return [URI]
    #
    def urify(path)
      uri = URI.parse(path)

      if uri.absolute?
        uri
      else
        URI.parse(File.join(endpoint, path))
      end
    end

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
    # Parse the response object and manipulate the result based on the given
    # +Content-Type+ header. For now, this method only parses JSON, but it
    # could be expanded in the future to accept other content types.
    #
    # @param [HTTP::Message] response
    #   the response object from the request
    #
    # @return [String, Hash]
    #   the parsed response, as an object
    #
    def parse_response(response)
      case response['Content-Type']
      when 'application/json'
        JSON.parse(response.body)
      else
        response.body
      end
    end

    #
    # Adds the default headers to the request object.
    #
    # @param [Net::HTTP::Request] request
    #
    def add_request_headers(request)
      headers = {
        'Accept'         => 'application/json',
        'Content-Type'   => 'application/json',
        'User-Agent'     => user_agent,
        'X-Chef-Version' => '11.4.0',
      }.merge(signed_header_auth(request))

      headers.each do |key, value|
        request.add_field(key, value)
      end
    end

    #
    # Use mixlib-auth to create a signed header auth.
    #
    # @param [Net::HTTP::Request] request
    #
    def signed_header_auth(request)
      unless defined?(Mixlib::Authentication)
        require 'mixlib/authentication/signedheaderauth'
      end

      verb = request.class.name.split('::').last.downcase
      url  = URI.parse(endpoint)
      private_key = parse_key(key)

      Mixlib::Authentication::SignedHeaderAuth.signing_object(
        :http_method => verb,
        :body        => request.body || '',
        :host        => "#{url.host}:#{url.port}",
        :path        => request.path,
        :timestamp   => Time.now.utc.iso8601,
        :user_id     => client,
        :file        => '',
      ).sign(private_key)
    end
  end
end
