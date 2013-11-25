module ChefAPI
  class Resource::Base
    class << self
      #
      # Get or set the schema for the remote resource. You probably only want
      # to call schema once with a block, because it will overwrite the
      # existing schema (meaning entries are not merged). If a block is given,
      # a new schema object is created, otherwise the current one is returned.
      #
      # @example
      #   schema do
      #     attribute :id, primary: true
      #     attribute :name, type: String, default: 'bacon'
      #     attribute :admin, type: Boolean, required: true
      #   end
      #
      # @return [Schema]
      #   the schema object for this resource
      #
      def schema(&block)
        if block
          @schema = Schema.new(&block)
        else
          @schema ||= Schema.new
        end
      end

      #
      # Get or set the name of the remote resource collection. This is most
      # likely the remote API endpoint (such as +/clients+), without the
      # leading slash.
      #
      # @example
      #   collection_name :clients
      #
      # @param [Symbol] value
      #   the value to use for the collection name.
      #
      # @return [Symbol]
      #   the name of the collection
      #
      def collection_name(value = nil)
        if value
          @collection_name = value
        else
          @collection_name ||
            raise(ArgumentError, "collection_name not set for #{self.class}")
        end
      end

      def build(attributes = {})
        new(attributes)
      end

      def find(id, params = {})
        build(connection.get("#{collection_name}/#{id}", params).body)
      end

      def all(params = {})
        records = connection.get("#{collection_name}", params).body

        records.collect do |record|
          find(record[0])
        end
      end
      alias_method :where, :all

      def first(*args)
        all(*args).first
      end

      def last(*args)
        all(*args).last
      end

      protected

        def connection
          @connection ||= ChefAPI::Client.new(
            'http://127.0.0.1:4000',
            'sethvargo',
            OpenSSL::PKey::RSA.new(File.read('/Users/sethvargo/.chef/sethvargo.pem'))
          ).send(:connection)
        end

    end

    attr_reader :schema

    def initialize(attributes = {})
      schema = self.class.schema.dup.load(attributes)
      schema.send(:compiled_schema).each do |key, value|
        instance_variable_set("@#{key}", value)
      end
    end

    def valid?
      schema.valid?
    end
  end
end
