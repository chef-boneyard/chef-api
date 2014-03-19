module ChefAPI
  class Resource::User < Resource::Base
    collection_path '/users'

    schema do
      attribute :username,   type: String,  primary: true, required: true
      attribute :admin,      type: Boolean, default: false
      attribute :public_key, type: String
    end

    class << self
      #
      # @see Base.each
      #
      def each(prefix = {}, &block)
        collection(prefix).each do |info|
          name = URI.escape(info['user']['username'])
          response = connection.get("/users/#{name}")
          result = from_json(response, prefix)

          block.call(result) if block
        end
      end

      #
      # Authenticate a user with the given +username+ and +password+.
      #
      # @note Requires Enterprise Chef
      #
      # @example Authenticate a user
      #   User.authenticate(username: 'user', password: 'pass')
      #     #=> { "status" => "linked", "user" => { ... } }
      #
      # @param [Hash] options
      #   the list of options to authenticate with
      #
      # @option options [String] username
      #   the username to authenticate with
      # @option options [String] password
      #   the plain-text password to authenticate with
      #
      # @return [Hash]
      #   the parsed JSON response from the server
      #
      def authenticate(options = {})
        connection.post('/authenticate_user', options)
      end
    end
  end
end
