module ChefAPI
  class Resource::User < Resource::Base
    collection_path '/users'

    schema do
      flavor :enterprise do
        attribute :username, type: String, primary: true, required: true

        # "Vanity" attributes
        attribute :first_name,      type: String
        attribute :middle_name,     type: String
        attribute :last_name,       type: String
        attribute :display_name,    type: String
        attribute :email,           type: String
        attribute :city,            type: String
        attribute :country,         type: String
        attribute :twitter_account, type: String
      end

      flavor :open_source do
        attribute :name, type: String, primary: true, required: true
      end

      attribute :admin,       type: Boolean, default: false
      attribute :public_key,  type: String
      attribute :private_key, type: [String, Boolean], default: false
    end

    has_many :organizations

    class << self
      #
      # @see Base.each
      #
      def each(prefix = {}, &block)
        users = collection(prefix)

        # HEC/EC returns a slightly different response than OSC/CZ
        if users.is_a?(Array)
          users.each do |info|
            name = URI.escape(info['user']['username'])
            response = connection.get("/users/#{name}")
            result = from_json(response, prefix)

            block.call(result) if block
          end
        else
          users.each do |_, path|
            response = connection.get(path)
            result = from_json(response, prefix)

            block.call(result) if block
          end
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
        connection.post('/authenticate_user', options.to_json)
      end
    end
  end
end
