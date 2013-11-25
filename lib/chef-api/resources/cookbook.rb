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

    has_many :versions,
      class_name: CookbookVersion,
      rest_endpoint: '/?num_versions=all'

    class << self
      def from_json(response, prefix = {})
        new(name: response.keys.first)
      end
    end
  end
end
