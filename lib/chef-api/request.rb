module ChefAPI
  #
  # A wrapper object around a client request that caches responses and waits
  # until the last possible minute to make a request.
  #
  # @example Make a request
  #   Request.new('http://...', :get) { # code to make request }
  #
  class Request
    attr_reader :verb
    attr_reader :url

    #
    # Create a new Request object.
    #
    # @param [String, Symbol] verb
    #   the HTTP verb
    # @param [String] url
    #   the full URL
    # @param [Proc] request
    #   the request object to call
    #
    # @return [ChefAPI::Request]
    #
    def initialize(verb, url, &request)
      @verb    = verb.to_s.upcase
      @url     = url
      @request = request
    end

    #
    # Gets the "raw" response body. This method will return the string contents
    # of the body from the given request.
    #
    # @example Get the body from the response
    #   request.body #=> "..."
    #
    # @return [String]
    #   the raw body response
    #
    def body
      @body ||= response.body
    end

    #
    # Gets the HTTP status response code.
    #
    # @example Get the response code from the response
    #   request.code #=> 200
    #
    # @return [Fixnum]
    #   the HTTP response code
    #
    def code
      @code ||= response.code.to_i
    end

    #
    # Determines if a response is "OK". A response is OK if it returned a 200
    # or 300 status.
    #
    # @example Check if a status is ok
    #   response.ok?
    # @example Check if s atatus is a success
    #   response.success?
    #
    # @return [Boolean]
    #   true if the response is OK, false otherwise
    #
    def ok?
      code.between?(200, 399)
    end
    alias_method :success?, :ok?

    #
    # Gets the response body and parses the given response as JSON. This method
    # will raise a +JSON::ParserError+ if the response is not valid JSON, so
    # you should handle that accordingly.
    #
    # @example Parse a response as JSON
    #   request.json #=> {  }
    #
    # @return [Hash]
    #   the parsed JSON response
    #
    def json
      @json ||= JSON.parse(body)
    end

    #
    # Gets the response body and parses the given response as XML. This method
    # will not raise an exception if the resposne is not valid XML, so you
    # should keep that in mind.
    #
    # @example Parse a response as XML
    #   request.xml #=> #<REXML::Document ...>
    #
    # @return [REXML::Document]
    #   the parsed XML response
    #
    def xml
      @xml ||= REXML::Document.new(body)
    end

    # @private
    def to_s
      "#<#{self.class} #{verb} #{url}>"
    end

    # @private
    def inspect
      if @response
        "#<#{self.class} #{verb} #{url} (#{code})>"
      else
        "#<#{self.class} #{verb} #{url} (pending)>"
      end
    end

    #
    # The raw response object, lazily evaluated.
    #
    # @raise [Error::BadRequest]
    #   if the response code is 400
    # @raise [Error::Unauthorized]
    #   if the response code is 401
    # @raise [Error::Forbidden]
    #   if the response code is 403
    # @raise [Error::NotFound]
    #   if the response code is 404
    # @raise [Error::MethodNotAllowed]
    #   if the response code is 405
    # @raise [Error::ConnectionError]
    #   if the response code is not successful
    #
    # @return [HTTPClient::Response]
    #
    def response
      return @response if @response

      @response = @request.call

      case @response.status.to_i
      when 400
        raise Error::BadRequest.new(url: url, body: @response.body)
      when 401
        raise Error::Unauthorized.new(url: url)
      when 403
        raise Error::Forbidden.new(url: url)
      when 404
        raise Error::NotFound.new(url: url)
      when 405
        raise Error::MethodNotAllowed.new(url: url)
      when 500..600
        raise Error::ConnectionError.new(url: url, body: @response.body)
      end

      @response
    rescue SocketError, Errno::ECONNREFUSED, EOFError
      raise Error::ConnectionError.new(url: url, body: <<-EOH.gsub(/^ {8}/, ''))
        The server is not currently accepting connections.
      EOH
    end
  end
end
