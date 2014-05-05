module ChefAPI
  class Resource::Search < Resource::Base
    collection_path '/search/:index'

    schema do
      attribute :total, type: Integer
      attribute :start, type: Integer
      attribute :rows,  type: Array
    end

    class << self
      #
      # About search : http://docs.opscode.com/essentials_search.html
      #
      # @param [String] index
      #   the name of the index to search
      # @param [String] query
      #   the query string
      # @param [Hash] options
      #   the query string
      #
      # @return [self]
      #   the current resource
      #
      def query(index, query = '*:*', options = {})
        return nil if index.nil?

        params = {}.tap do |o|
          o[:q]     = query
          o[:rows]  = options[:rows]  || 1000
          o[:sort]  = options[:sort]  || 'X_CHEF_id_CHEF_X'
          o[:start] = options[:start] || 0
        end

        path = expanded_collection_path(index: index.to_s)
        response = connection.get(path, params)
        from_json(response, index: index.to_s)
      end
    end
  end
end
