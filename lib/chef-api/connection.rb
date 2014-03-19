require 'net/http'
require 'net/https'
require 'openssl'
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
      #     Get the list of $1 for this {Connection}. This method is threadsafe.
      #
      #     @example Get the $1 from this {Connection} object
      #       connection = ChefAPI::Connection.new('...')
      #       connection.$1 #=> $2(attribute1, attribute2, ...)
      #
      #     @return [Class<$2>]
      #
      def proxy(name, klass)
        class_eval <<-EOH, __FILE__, __LINE__ + 1
          def #{name}
            Thread.current['chefapi.connection'] = self
            #{klass}
          end
        EOH
      end
    end

    include Logify
    include ChefAPI::Configurable

    proxy :clients,      'Resource::Client'
    proxy :cookbooks,    'Resource::Cookbook'
    proxy :data_bags,    'Resource::DataBag'
    proxy :environments, 'Resource::Environment'
    proxy :nodes,        'Resource::Node'
    proxy :principals,   'Resource::Principal'
    proxy :roles,        'Resource::Role'
    proxy :users,        'Resource::User'

    #
    # Create a new ChefAPI Connection with the given options. Any options
    # given take precedence over the default options.
    #
    # @example Create a connection object from a list of options
    #   ChefAPI::Connection.new(
    #     endpoint: 'https://...',
    #     client:   'bacon',
    #     key:      '~/.chef/bacon.pem',
    #   )
    #
    # @example Create a connection object using a block
    #   ChefAPI::Connection.new do |connection|
    #     connection.endpoint = 'https://...'
    #     connection.client   = 'bacon'
    #     connection.key      = '~/.chef/bacon.pem'
    #   end
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

      yield self if block_given?
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
    # @param path (see Connection#request)
    # @param [Hash] params
    #   the list of query params
    #
    # @raise (see Connection#request)
    # @return (see Connection#request)
    #
    def get(path, params = {})
      request(:get, path, params)
    end

    #
    # Make a HTTP POST request
    #
    # @param path (see Connection#request)
    # @param [String, #read] data
    #   the body to use for the request
    #
    # @raise (see Connection#request)
    # @return (see Connection#request)
    #
    def post(path, data)
      request(:post, path, data)
    end

    #
    # Make a HTTP PUT request
    #
    # @param path (see Connection#request)
    # @param data (see Connection#post)
    #
    # @raise (see Connection#request)
    # @return (see Connection#request)
    #
    def put(path, data)
      request(:put, path, data)
    end

    #
    # Make a HTTP PATCH request
    #
    # @param path (see Connection#request)
    # @param data (see Connection#post)
    #
    # @raise (see Connection#request)
    # @return (see Connection#request)
    #
    def patch(path, data)
      request(:patch, path, data)
    end

    #
    # Make a HTTP DELETE request
    #
    # @param path (see Connection#request)
    # @param params (see Connection#get)
    #
    # @raise (see Connection#request)
    # @return (see Connection#request)
    #
    def delete(path, params = {})
      request(:delete, path, params)
    end

    #
    # Make an HTTP request with the given verb, data, params, and headers. If
    # the response has a return type of JSON, the JSON is automatically parsed
    # and returned as a hash; otherwise it is returned as a string.
    #
    # @raise [Error::HTTPError]
    #   if the request is not an HTTP 200 OK
    #
    # @param [Symbol] verb
    #   the lowercase symbol of the HTTP verb (e.g. :get, :delete)
    # @param [String] path
    #   the absolute or relative path from {Defaults.endpoint} to make the
    #   request against
    # @param [#read, Hash, nil] data
    #   the data to use (varies based on the +verb+)
    #
    # @return [String, Hash]
    #   the response body
    #
    def request(verb, path, data = {})
      log.info "#{verb.to_s.upcase} #{path}..."

      # Build the URI and request object from the given information
      uri = build_uri(verb, path, data)
      request = class_for_request(verb).new(uri.request_uri)

      # Add request headers
      add_request_headers(request)

      # Setup PATCH/POST/PUT
      if [:patch, :post, :put].include?(verb)
        if data.respond_to?(:read)
          request.body_stream = data
        elsif data.is_a?(Hash)
          request.form_data = data
        else
          request.body = data
        end
      end

      # Sign the request
      add_signing_headers(verb, uri, request, parsed_key)

      # Create the HTTP connection object - since the proxy information defaults
      # to +nil+, we can just pass it to the initializer method instead of doing
      # crazy strange conditionals.
      connection = Net::HTTP.new(uri.host, uri.port,
        proxy_address, proxy_port, proxy_username, proxy_password)

      # Apply SSL, if applicable
      if uri.scheme == 'https'
        # Turn on SSL
        connection.use_ssl = true

        # Custom pem files, no problem!
        if ssl_pem_file
          pem = File.read(ssl_pem_file)
          connection.cert = OpenSSL::X509::Certificate.new(pem)
          connection.key = OpenSSL::PKey::RSA.new(pem)
          connection.verify_mode = OpenSSL::SSL::VERIFY_PEER
        end

        # Naughty, naughty, naughty! Don't blame when when someone hops in
        # and executes a MITM attack!
        unless ssl_verify
          log.warn "Disabling SSL verification..."
          log.warn "Neither ChefAPI nor the maintainers are responsible for " \
            "damanges incurred as a result of disabling SSL verification. " \
            "Please use this with extreme caution, or consider specifying " \
            "a custom certificate using `config.ssl_pem_file'."
          connection.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
      end

      # Create a connection using the block form, which will ensure the socket
      # is properly closed in the event of an error.
      connection.start do |http|
        response = http.request(request)

        case response
        when Net::HTTPRedirection
          redirect = URI.parse(response['location'])
          log.debug "Performing HTTP redirect to #{redirect}"
          request(verb, redirect, params)
        when Net::HTTPSuccess
          success(response)
        else
          error(response)
        end
      end
    rescue SocketError, Errno::ECONNREFUSED, EOFError
      log.warn "Unable to reach the Chef Server"
      raise Error::HTTPServerUnavailable.new
    end

    #
    # Construct a URL from the given verb and path. If the request is a GET or
    # DELETE request, the params are assumed to be query params are are
    # converted as such using {Connection#to_query_string}.
    #
    # If the path is relative, it is merged with the {Defaults.endpoint}
    # attribute. If the path is absolute, it is converted to a URI object and
    # returned.
    #
    # @param [Symbol] verb
    #   the lowercase HTTP verb (e.g. :+get+)
    # @param [String] path
    #   the absolute or relative HTTP path (url) to get
    # @param [Hash] params
    #   the list of params to build the URI with (for GET and DELETE requests)
    #
    # @return [URI]
    #
    def build_uri(verb, path, params = {})
      log.info  "Building URI..."

      # Add any query string parameters
      if [:delete, :get].include?(verb)
        log.debug "Detected verb deserves a querystring"
        log.debug "Building querystring using #{params.inspect}"
        path = [path, to_query_string(params)].compact.join('?')
      end

      # Parse the URI
      uri = URI.parse(path)

      # Don't merge absolute URLs
      unless uri.absolute?
        log.debug "Detected URI is relative"
        log.debug "Appending #{endpoint} to #{path}"
        uri = URI.parse(File.join(endpoint, path))
      end

      # Return the URI object
      uri
    end

    #
    # Helper method to get the corresponding +Net::HTTP+ class from the given
    # HTTP verb.
    #
    # @param [#to_s] verb
    #   the HTTP verb to create a class from
    #
    # @return [Class]
    #
    def class_for_request(verb)
      Net::HTTP.const_get(verb.to_s.capitalize)
    end

    #
    # Convert the given hash to a list of query string parameters. Each key and
    # value in the hash is URI-escaped for safety.
    #
    # @param [Hash] hash
    #   the hash to create the query string from
    #
    # @return [String, nil]
    #   the query string as a string, or +nil+ if there are no params
    #
    def to_query_string(hash)
      hash.map do |key, value|
        "#{URI.escape(key.to_s)}=#{URI.escape(value.to_s)}"
      end.join('&')[/.+/]
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
    # @return [OpenSSL::PKey::RSA]
    #   the RSA private key as an OpenSSL object
    #
    def parsed_key
      return @parsed_key if @parsed_key

      log.info "Parsing private key..."

      if key.nil?
        log.warn "No private key given!"
        raise 'No private key given!'
      end

      if key.is_a?(OpenSSL::PKey::RSA)
        log.debug "Detected private key is an OpenSSL Ruby object"
        @parsed_key = key
      end

      if key =~ /(.+)\.pem$/ || File.exists?(key)
        log.debug "Detected private key is the path to a file"
        contents = File.read(File.expand_path(key))
        @parsed_key = OpenSSL::PKey::RSA.new(contents)
      else
        log.debug "Detected private key was the literal string key"
        @parsed_key = OpenSSL::PKey::RSA.new(key)
      end

      @parsed_key
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
    def success(response)
      log.info "Parsing response as success..."

      case response['Content-Type']
      when 'application/json'
        log.debug "Detected response as JSON"
        log.debug "Parsing response body as JSON"
        JSON.parse(response.body)
      else
        log.debug "Detected response as text/plain"
        response.body
      end
    end

    #
    # Raise a response error, extracting as much information from the server's
    # response as possible.
    #
    # @param [HTTP::Message] response
    #   the response object from the request
    #
    def error(response)
      log.info "Parsing response as error..."

      case response['Content-Type']
      when 'application/json'
        log.debug "Detected error response as JSON"
        log.debug "Parsing error response as JSON"
        message = JSON.parse(response.body)['error'].first
      else
        log.debug "Detected response as text/plain"
        message = response.body
      end

      case response.code.to_i
      when 400
        raise Error::HTTPBadRequest.new(message: message)
      when 401
        raise Error::HTTPUnauthorizedRequest.new(message: message)
      when 403
        raise Error::HTTPForbiddenRequest.new(message: message)
      when 404
        raise Error::HTTPNotFound.new(message: message)
      when 405
        raise Error::HTTPMethodNotAllowed.new(message: message)
      when 406
        raise Error::HTTPNotAcceptable.new(message: message)
      when 504
        raise Error::HTTPGatewayTimeout.new(message: message)
      when 500..600
        raise Error::HTTPServerUnavailable.new
      else
        raise "I got an error #{response.code} that I don't know how to handle!"
      end
    end

    #
    # Adds the default headers to the request object.
    #
    # @param [Net::HTTP::Request] request
    #
    def add_request_headers(request)
      log.info "Adding request headers..."

      headers = {
        'Accept'         => 'application/json',
        'Content-Type'   => 'application/json',
        'Connection'     => 'keep-alive',
        'Keep-Alive'     => '30',
        'User-Agent'     => user_agent,
        'X-Chef-Version' => '11.4.0',
      }

      headers.each do |key, value|
        log.debug "#{key}: #{value}"
        request[key] = value
      end
    end

    #
    # Use mixlib-auth to create a signed header auth.
    #
    # @param [Net::HTTP::Request] request
    #
    def add_signing_headers(verb, uri, request, key)
      log.info "Adding signed header authentication..."

      unless defined?(Mixlib::Authentication::SignedHeaderAuth)
        require 'mixlib/authentication/signedheaderauth'
      end

      headers = Mixlib::Authentication::SignedHeaderAuth.signing_object(
        :http_method => verb,
        :body        => request.body || '',
        :host        => "#{uri.host}:#{uri.port}",
        :path        => uri.path,
        :timestamp   => Time.now.utc.iso8601,
        :user_id     => client,
        :file        => '',
      ).sign(key)

      headers.each do |key, value|
        log.debug "#{key}: #{value}"
        request[key] = value
      end
    end
  end
end
