module ChefAPI
  class Resource::CollectionProxy
    include Enumerable

    #
    # Create a new collection proxy from the given parent class and collection
    # information. The collection proxy aims to make working with nested
    # resource collections a bit easier. The proxy waits until non-existing
    # data is requested before making another HTTP request. In this way, it
    # helps reduce bandwidth and API requets.
    #
    # Additionally, the collection proxy caches the results of an object request
    # in memory by +id+, so additional requests for the same object will hit the
    # cache, again reducing HTTP requests.
    #
    # @param [Resource::Base] parent
    #   the parent resource that created the collection
    # @param [Class] klass
    #   the class the resulting objects should be
    # @param [String] endpoint
    #   the relative path for the RESTful endpoint
    #
    # @return [CollectionProxy]
    #
    def initialize(parent, klass, endpoint, prefix = {})
      @parent     = parent
      @klass      = klass
      @endpoint   = "#{parent.resource_path}/#{endpoint}"
      @prefix     = prefix
      @collection = load_collection
    end

    #
    # Force a reload of this collection proxy and all its elements. This is
    # useful if you think additional items have been added to the remote
    # collection and need access to them locally. This will also clear any
    # existing cached responses, so use with caution.
    #
    # @return [self]
    #
    def reload!
      cache.clear
      @collection = load_collection

      self
    end

    #
    # Fetch a specific resource in the collection by id.
    #
    # @example Fetch a resource
    #   Bacon.first.items.fetch('crispy')
    #
    # @param [String, Symbol] id
    #   the id of the resource to fetch
    #
    # @return [Resource::Base, nil]
    #   the fetched class, or nil if it does not exists
    #
    def fetch(id)
      return nil unless exists?(id)
      cached(id) { klass.from_url(get(id), prefix) }
    end

    #
    # Determine if the resource with the given id exists on the remote Chef
    # Server. This method does not actually query the Chef Server, but rather
    # delegates to the cached collection. To guarantee the most fresh set of
    # data, you should call +reload!+ before +exists?+ to ensure you have the
    # most up-to-date collection of resources.
    #
    # @param [String, Symbol] id
    #   the unique id of the resource to find.
    #
    # @return [Boolean]
    #   true if the resource exists, false otherwise
    #
    def exists?(id)
      collection.has_key?(id.to_s)
    end

    #
    # Get the full list of all entries in the collection. This method is
    # incredibly expensive and should only be used when you absolutely need
    # all resources. If you need a specific resource, you should use an iterator
    # such as +select+ or +find+ instead, since it will minimize HTTP requests.
    # Once all the objects are requested, they are cached, reducing the number
    # of HTTP requests.
    #
    # @return [Array<Resource::Base>]
    #
    def all
      entries
    end

    #
    # The custom iterator for looping over each object in this collection. For
    # more information, please see the +Enumerator+ module in Ruby core.
    #
    def each(&block)
      collection.each do |id, url|
        object = cached(id) { klass.from_url(url, prefix) }
        block.call(object) if block
      end
    end

    #
    # The total number of items in this collection. This method does not make
    # an API request, but rather counts the number of keys in the given
    # collection.
    #
    def count
      collection.length
    end
    alias_method :size, :count

    #
    # The string representation of this collection proxy.
    #
    # @return [String]
    #
    def to_s
      "#<#{self.class.name}>"
    end

    #
    # The detailed string representation of this collection proxy.
    #
    # @return [String]
    #
    def inspect
      objects = collection
        .map { |id, _| cached(id) || klass.new(klass.schema.primary_key => id) }
        .map { |object| object.to_s }

      "#<#{self.class.name} [#{objects.join(', ')}]>"
    end

    private

    attr_reader :collection
    attr_reader :endpoint
    attr_reader :klass
    attr_reader :parent
    attr_reader :prefix

    #
    # Fetch the object collection from the Chef Server. Since the Chef Server's
    # API is completely insane and all over the place, it might return a Hash
    # where the key is the id of the resource and the value is the url for that
    # item on the Chef Server:
    #
    #     { "key" => "url" }
    #
    # Or if the Chef Server's fancy is tickled, it might just return an array
    # of the list of items:
    #
    #     ["item_1", "item_2"]
    #
    # Or if the Chef Server is feeling especially magical, it might return the
    # actual objects, but prefixed with the JSON id:
    #
    #     [{"organization" => {"_id" => "..."}}, {"organization" => {...}}]
    #
    # So, this method attempts to intelligent handle these use cases. That being
    # said, I can almost guarantee that someone is going to do some crazy
    # strange edge case with this library and hit a bug here, so it will likely
    # be changed in the future. For now, it "works on my machine".
    #
    # @return [Hash]
    #
    def load_collection
      case response = Resource::Base.connection.get(endpoint)
      when Array
        if response.first.is_a?(Hash)
          key = klass.schema.primary_key.to_s

          {}.tap do |hash|
            response.each do |results|
              results.each do |_, info|
                hash[key] = klass.resource_path(info[key])
              end
            end
          end
        else
          Hash[*response.map { |item| [item, klass.resource_path(item)] }.flatten]
        end
      when Hash
        response
      end
    end

    #
    # Retrieve a cached value. This method helps significantly reduce the
    # number of HTTP requests made against the remote server.
    #
    # @param [String, Symbol] key
    #   the cache key (typically the +name+ of the resource)
    # @param [Proc] block
    #   the block to evaluate to set the value if it doesn't exist
    #
    # @return [Object]
    #   the value at the cache
    #
    def cached(key, &block)
      cache[key.to_sym] ||= block ? block.call : nil
    end

    #
    # The cache...
    #
    # @return [Hash]
    #
    def cache
      @cache ||= {}
    end

    #
    # Retrieve a specific item in the collection. Note, this will always return
    # the original raw record (with the key => URL pairing), not a cached
    # resource.
    #
    # @param [String, Symbol] id
    #   the id of the resource to fetch
    #
    # @return [String, nil]
    #   the URL to retrieve the item in the collection, or nil if it does not
    #   exist
    #
    def get(id)
      collection[id.to_s]
    end
  end
end
