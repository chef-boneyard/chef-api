module ChefAPI
  class Resource::Search < Resource::Base
    collection_path '/search/:index?:query'

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

        opts = {}.tap do |o|
          o[:rows]  = options[:rows]  || 1000
          o[:sort]  = options[:sort]  || 'X_CHEF_id_CHEF_X'
          o[:start] = options[:start] || 0
        end

        prefix = {}.tap do |p|
          p[:index] = index.to_s
          p[:query] = build_query(query, opts)
        end

        if options[:keys]
          response = post(options[:keys].to_json, prefix)
          response['rows'].map! { |row| row['data'] }
        else
          path = expanded_collection_path(prefix)
          response = connection.get(path)
        end

        from_json(response, prefix)
      end

      def build_query(query = '*:*', options = {})
        query_string =  "q=#{escape(query)}"
        query_string << "&rows=#{escape(options[:rows])}"   if options[:rows]
        query_string << "&sort=#{escape(options[:sort])}"   if options[:sort]
        query_string << "&start=#{escape(options[:start])}" if options[:start]
        query_string
      end

      private

      def escape(string)
        string && URI.escape(string.to_s)
      end

    end
  end
end
