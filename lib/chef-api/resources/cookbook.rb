module ChefAPI
  #
  # In the real world, a "cookbook" is a single entity with multiple versions.
  # In Chef land, a "cookbook" is actually just a wrapper around a collection
  # of +cookbook_version+ objects that fully detail the layout of a cookbook.
  #
  class Resource::Cookbook < Resource::Base
    collection_path '/cookbooks'

    schema do
      attribute :name, type: String, primary: true, required: true
    end

    class << self
      #
      #
      #
      def each(prefix = {}, &block)
        collection(prefix).each do |name, info|
          response = connection.get(info['url'])
          result = from_json(response, prefix)

          block.call(result) if block
        end
      end

      #
      # Load the response from the given JSON. Since cookbooks are really just
      # a "meta" object that wraps a collection of cookbook versions, the JSON
      # is not very RESTful and does not fit the existing schema defined by most
      # every other resource. Here is a sample JSON response:
      #
      #     {
      #       "apache2": {
      #         "url": "http://localhost:4000/cookbooks/apache2",
      #         "versions": [
      #           {
      #             "url": "http://localhost:4000/cookbooks/apache2/1.0.0",
      #             "version": "1.0.0"
      #           }
      #         ]
      #       }
      #     }
      #
      # @param (see Resource::Base.from_json)
      # @return (see Resource::Base.from_json)
      #
      def from_json(response, prefix = {})
        new(name: response.keys.first)
      end
    end

    #
    #
    #
    def versions
      associations[:versions] ||= Resource::CookbookVersionCollectionProxy.new(self)
    end
  end
end

module ChefAPI
  #
  # The mutable collection is a special kind of collection proxy that permits
  # Rails-like attribtue creation, like:
  #
  #   Cookbook.first.versions.create(version: '1.0.0')
  #
  class Resource::CookbookVersionCollectionProxy < Resource::CollectionProxy
    def initialize(cookbook)
      # Delegate to the superclass
      super(cookbook, Resource::CookbookVersion, nil, cookbook: cookbook.name)
    end

    def load_collection
      response = Resource::Base.connection.get(endpoint)

      {}.tap do |hash|
        response[parent.id]['versions'].each do |info|
          hash["#{parent.id}-#{info['version']}"] = info['url']
        end
      end
    end

    # @see klass.new
    def new(data = {})
      klass.new(data, prefix)
      # klass.new(data, prefix, parent)
    end

    # @see klass.destroy
    def destroy(id)
      klass.destroy(id, prefix)
    ensure
      reload!
    end

    # @see klass.destroy_all
    def destroy_all
      klass.destroy_all(prefix)
    ensure
      reload!
    end

    # @see klass.build
    def build(data = {})
      klass.build(data, prefix)
    end

    # @see klass.create
    def create(data = {})
      klass.create(data, prefix)
    ensure
      reload!
    end

    # @see klass.create!
    def create!(data = {})
      klass.create!(data, prefix)
    ensure
      reload!
    end

    # @see klass.update
    def update(id, data = {})
      klass.update(id, data, prefix)
    end
  end
end
