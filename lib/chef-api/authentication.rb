require 'base64'
require 'digest'
require 'openssl'
require 'time'

#
# DEBUG steps:
#
# check .chomp
#

module ChefAPI
  class Authentication
    include Logify

    # @todo: Enable this in the future when Mixlib::Authentication supports
    # signing the full request body instead of just the uploaded file parameter.
    SIGN_FULL_BODY = false

    SIGNATURE = 'algorithm=sha1;version=1.0;'.freeze

    # Headers
    X_OPS_SIGN          = 'X-Ops-Sign'.freeze
    X_OPS_USERID        = 'X-Ops-Userid'.freeze
    X_OPS_TIMESTAMP     = 'X-Ops-Timestamp'.freeze
    X_OPS_CONTENT_HASH  = 'X-Ops-Content-Hash'.freeze
    X_OPS_AUTHORIZATION = 'X-Ops-Authorization'.freeze

    class << self
      #
      # Create a new signing object from the given options. All options are
      # required.
      #
      # @see (#initialize)
      #
      # @option options [String] :user
      # @option options [String, OpenSSL::PKey::RSA] :key
      # @option options [String, Symbol] verb
      # @option options [String] :path
      # @option options [String, IO] :body
      #
      def from_options(options = {})
        user = options.fetch(:user)
        key  = options.fetch(:key)
        verb = options.fetch(:verb)
        path = options.fetch(:path)
        body = options.fetch(:body)

        new(user, key, verb, path, body)
      end
    end

    #
    # Create a new Authentication object for signing. Creating an instance will
    # not run any validations or perform any operations (this is on purpose).
    #
    # @param [String] user
    #   the username/client/user of the user to sign the request. In Hosted
    #   Chef land, this is your "client". In Supermarket land, this is your
    #   "username".
    # @param [String, OpenSSL::PKey::RSA] key
    #   the path to a private key on disk, the raw private key (as a String),
    #   or the raw private key (as an OpenSSL::PKey::RSA instance)
    # @param [Symbol, String] verb
    #   the verb for the request (e.g. +:get+)
    # @param [String] path
    #   the "path" part of the URI (e.g. +/path/to/resource+)
    # @param [String, IO] body
    #   the body to sign for the request, as a raw string or an IO object to be
    #   read in chunks
    #
    def initialize(user, key, verb, path, body)
      @user = user
      @key  = key
      @verb = verb
      @path = path
      @body = body
    end

    #
    # The fully-qualified headers for this authentication object of the form:
    #
    #   {
    #     'X-Ops-Sign'            => 'algorithm=sha1;version=1.1',
    #     'X-Ops-Userid'          => 'sethvargo',
    #     'X-Ops-Timestamp'       => '2014-07-07T02:17:15Z',
    #     'X-Ops-Content-Hash'    => '...',
    #     'x-Ops-Authorization-1' => '...'
    #     'x-Ops-Authorization-2' => '...'
    #     'x-Ops-Authorization-3' => '...'
    #     # ...
    #   }
    #
    # @return [Hash]
    #   the signing headers
    #
    def headers
      {
        X_OPS_SIGN         => SIGNATURE,
        X_OPS_USERID       => @user,
        X_OPS_TIMESTAMP    => canonical_timestamp,
        X_OPS_CONTENT_HASH => content_hash,
      }.merge(signature_lines)
    end

    #
    # The canonical body. This could be an IO object (such as +#body_stream+),
    # an actual string (such as +#body+), or just the empty string if the
    # request's body and stream was nil.
    #
    # @return [String, IO]
    #
    def content_hash
      return @content_hash if @content_hash

      if SIGN_FULL_BODY
        @content_hash = hash(@body || '').chomp
      else
        if @body.is_a?(Multipart::MultiIO)
          filepart = @body.ios.find { |io| io.is_a?(Multipart::MultiIO) }
          file     = filepart.ios.find { |io| !io.is_a?(StringIO) }

          @content_hash = hash(file).chomp
        else
          @content_hash = hash(@body || '').chomp
        end
      end

      @content_hash
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
    # @return [OpenSSL::PKey::RSA]
    #   the RSA private key as an OpenSSL object
    #
    def canonical_key
      return @canonical_key if @canonical_key

      log.info "Parsing private key..."

      if @key.nil?
        log.warn "No private key given!"
        raise 'No private key given!'
      end

      if @key.is_a?(OpenSSL::PKey::RSA)
        log.debug "Detected private key is an OpenSSL Ruby object"
        @canonical_key = @key
      elsif @key =~ /(.+)\.pem$/ || File.exists?(File.expand_path(@key))
        log.debug "Detected private key is the path to a file"
        contents = File.read(File.expand_path(@key))
        @canonical_key = OpenSSL::PKey::RSA.new(contents)
      else
        log.debug "Detected private key was the literal string key"
        @canonical_key = OpenSSL::PKey::RSA.new(@key)
      end

      @canonical_key
    end


    #
    # The canonical path, with duplicate and trailing slashes removed. This
    # value is then hashed.
    #
    # @example
    #   "/zip//zap/foo" #=> "/zip/zap/foo"
    #
    # @return [String]
    #
    def canonical_path
      @canonical_path ||= hash(@path.squeeze('/').gsub(/(\/)+$/,'')).chomp
    end

    #
    # The iso8601 timestamp for this request. This value must be cached so it
    # is persisted throughout this entire request.
    #
    # @return [String]
    #
    def canonical_timestamp
      @canonical_timestamp ||= Time.now.utc.iso8601
    end

    #
    # The uppercase verb.
    #
    # @example
    #   :get #=> "GET"
    #
    # @return [String]
    #
    def canonical_method
      @canonical_method ||= @verb.to_s.upcase
    end

    #
    # The canonical request, from the path, body, user, and current timestamp.
    #
    # @return [String]
    #
    def canonical_request
      [
        "Method:#{canonical_method}",
        "Hashed Path:#{canonical_path}",
        "X-Ops-Content-Hash:#{content_hash}",
        "X-Ops-Timestamp:#{canonical_timestamp}",
        "X-Ops-UserId:#{@user}",
      ].join("\n")
    end

    #
    # The canonical request, encrypted by the given private key.
    #
    # @return [String]
    #
    def encrypted_request
      canonical_key.private_encrypt(canonical_request)
    end

    #
    # The +X-Ops-Authorization-N+ headers. This method takes the encrypted
    # request, splits on a newline, and creates a signed header authentication
    # request. N begins at 1, not 0 because the original author of
    # Mixlib::Authentication did not believe in computer science.
    #
    # @return [Hash]
    #
    def signature_lines
      signature = Base64.encode64(encrypted_request)
      signature.split(/\n/).each_with_index.inject({}) do |hash, (line, index)|
        hash["#{X_OPS_AUTHORIZATION}-#{index + 1}"] = line
        hash
      end
    end

    private

    #
    # Hash the given object.
    #
    # @param [String, IO] object
    #   a string or IO object to hash
    #
    # @return [String]
    #   the hashed value
    #
    def hash(object)
      if object.respond_to?(:read)
        digest_io(object)
      else
        digest_string(object)
      end
    end

    #
    # Digest the given IO, reading in 1024 bytes at one time.
    #
    # @param [IO] io
    #   the IO (or File object)
    #
    # @return [String]
    #
    def digest_io(io)
      digester = Digest::SHA1.new

      while buffer = io.read(1024)
        digester.update(buffer)
      end

      io.rewind

      Base64.encode64(digester.digest)
    end

    #
    # Digest a string.
    #
    # @param [String] string
    #   the string to digest
    #
    # @return [String]
    #
    def digest_string(string)
      Base64.encode64(Digest::SHA1.digest(string))
    end
  end
end
