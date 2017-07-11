require 'net/http'
require 'net/https'
require 'openssl'
require 'uri'

module ChefAPI
  #
  # Connection object for the ChefAPI API.
  #
  # @see https://docs.chef.io/api_chef_server.html
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

    proxy :clients,        'Resource::Client'
    proxy :cookbooks,      'Resource::Cookbook'
    proxy :data_bags,      'Resource::DataBag'
    proxy :environments,   'Resource::Environment'
    proxy :nodes,          'Resource::Node'
    proxy :partial_search, 'Resource::PartialSearch'
    proxy :principals,     'Resource::Principal'
    proxy :roles,          'Resource::Role'
    proxy :search,         'Resource::Search'
    proxy :users,          'Resource::User'
    proxy :organizations,  'Resource::Organization'

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
    # @param request_options (see Connection#request)
    #
    # @raise (see Connection#request)
    # @return (see Connection#request)
    #
    def get(path, params = {}, request_options = {})
      request(:get, path, params)
    end

    #
    # Make a HTTP POST request
    #
    # @param path (see Connection#request)
    # @param [String, #read] data
    #   the body to use for the request
    # @param [Hash] params
    #   the list of query params
    # @param request_options (see Connection#request)
    #
    # @raise (see Connection#request)
    # @return (see Connection#request)
    #
    def post(path, data, params = {}, request_options = {})
      request(:post, path, data, params)
    end

    #
    # Make a HTTP PUT request
    #
    # @param path (see Connection#request)
    # @param data (see Connection#post)
    # @param params (see Connection#post)
    # @param request_options (see Connection#request)
    #
    # @raise (see Connection#request)
    # @return (see Connection#request)
    #
    def put(path, data, params = {}, request_options = {})
      request(:put, path, data, params)
    end

    #
    # Make a HTTP PATCH request
    #
    # @param path (see Connection#request)
    # @param data (see Connection#post)
    # @param params (see Connection#post)
    # @param request_options (see Connection#request)
    #
    # @raise (see Connection#request)
    # @return (see Connection#request)
    #
    def patch(path, data, params = {}, request_options = {})
      request(:patch, path, data, params)
    end

    #
    # Make a HTTP DELETE request
    #
    # @param path (see Connection#request)
    # @param params (see Connection#get)
    # @param request_options (see Connection#request)
    #
    # @raise (see Connection#request)
    # @return (see Connection#request)
    #
    def delete(path, params = {}, request_options = {})
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
    # @param [Hash] params
    #   the params to use for :patch, :post, :put
    # @param [Hash] request_options
    #   the list of options/configurables for the actual request
    #
    # @option request_options [true, false] :sign (default: +true+)
    #   whether to sign the request using mixlib authentication headers
    #
    # @return [String, Hash]
    #   the response body
    #
    def request(verb, path, data = {}, params = {}, request_options = {})
      log.info  "#{verb.to_s.upcase} #{path}..."
      log.debug "Chef flavor: #{flavor.inspect}"

      # Build the URI and request object from the given information
      if [:delete, :get].include?(verb)
        uri = build_uri(verb, path, data)
      else
        uri = build_uri(verb, path, params)
      end
      request = class_for_request(verb).new(uri.request_uri)

      # Add request headers
      add_request_headers(request)

      # Setup PATCH/POST/PUT
      if [:patch, :post, :put].include?(verb)
        if data.respond_to?(:read)
          log.info "Detected file/io presence"
          request.body_stream = data
        elsif data.is_a?(Hash)
          # If any of the values in the hash are File-like, assume this is a
          # multi-part post
          if data.values.any? { |value| value.respond_to?(:read) }
            log.info "Detected multipart body"

            multipart = Multipart::Body.new(data)

            log.debug "Content-Type: #{multipart.content_type}"
            log.debug "Content-Length: #{multipart.content_length}"

            request.content_length = multipart.content_length
            request.content_type   = multipart.content_type

            request.body_stream    = multipart.stream
          else
            log.info "Detected form data"
            request.form_data = data
          end
        else
          log.info "Detected regular body"
          request.body = data
        end
      end

      # Sign the request
      if request_options[:sign] == false
        log.info "Skipping signed header authentication (user requested)..."
      else
        add_signing_headers(verb, uri.path, request)
      end

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
            "damages incurred as a result of disabling SSL verification. " \
            "Please use this with extreme caution, or consider specifying " \
            "a custom certificate using `config.ssl_pem_file'."
          connection.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
      end

      # Create a connection using the block form, which will ensure the socket
      # is properly closed in the event of an error.
      connection.start do |http|
        response = http.request(request)

        log.debug "Raw response:"
        log.debug response.body

        case response
        when Net::HTTPRedirection
          redirect = URI.parse(response['location']).to_s
          log.debug "Performing HTTP redirect to #{redirect}"
          request(verb, redirect, data)
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
      if querystring = to_query_string(params)
        log.debug "Detected verb deserves a querystring"
        log.debug "Building querystring using #{params.inspect}"
        log.debug "Compiled querystring is #{querystring.inspect}"
        path = [path, querystring].compact.join('?')
      end

      # Parse the URI
      uri = URI.parse(path)

      # Don't merge absolute URLs
      unless uri.absolute?
        log.debug "Detected URI is relative"
        log.debug "Appending #{path} to #{endpoint}"
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
      when /json/
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
      when /json/
        log.debug "Detected error response as JSON"
        log.debug "Parsing error response as JSON"
        message = JSON.parse(response.body)
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
    # Create a signed header authentication that can be consumed by
    # +Mixlib::Authentication+.
    #
    # @param [Symbol] verb
    #   the HTTP verb (e.g. +:get+)
    # @param [String] path
    #   the requested URI path (e.g. +/resources/foo+)
    # @param [Net::HTTP::Request] request
    #
    def add_signing_headers(verb, path, request)
      log.info "Adding signed header authentication..."

      authentication = Authentication.from_options(
        user: client,
        key:  key,
        verb: verb,
        path: path,
        body: request.body || request.body_stream,
      )

      authentication.headers.each do |key, value|
        log.debug "#{key}: #{value}"
        request[key] = value
      end

      if request.body_stream
        request.body_stream.rewind
      end
    end
  end
end
