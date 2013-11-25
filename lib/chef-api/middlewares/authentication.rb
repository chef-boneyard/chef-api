module ChefAPI
  class Middleware::Authentication < Faraday::Middleware
    dependency do
      require 'mixlib/authentication/signedheaderauth'
      require 'uri'
    end

    #
    # @param [Faraday::Application] app
    # @param [String] client
    #   the name of the client to use for Chef
    # @param [OpenSSL::PKey::RSA] key
    #   the RSA private key to sign with
    #
    def initialize(app, client, key)
      super(app)

      @client = client
      @key    = key
    end

    def call(env)
      env[:request_headers].merge!(default_headers)
      env[:request_headers].merge!(signing_object(env))
      @app.call(env)
    end

    private

      def signing_object(env)
        object = Mixlib::Authentication::SignedHeaderAuth.signing_object(
          http_method: env[:method],
          body: env[:body] || '',
          host: "#{env[:url].host}:#{env[:url].port}",
          path:  env[:url].path,
          timestamp: Time.now.utc.iso8601,
          user_id: @client,
          file: '',
          proto_version: '1.0',
        )
        object.sign(@key)
      end

      def default_headers
        {
          'Accept'         => 'application/json',
          'Content-Type'   => 'application/json',
          'X-Chef-Version' => '11.4.0',
        }
      end

  end
end
