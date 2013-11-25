module ChefAPI
  class Resource::Environment < Resource::Base
    collection_path '/environments'

    schema do
      attribute :name,                type: String, primary: true, required: true
      attribute :description,         type: String
      attribute :default_attributes,  type: Hash,   default: {}
      attribute :override_attributes, type: Hash,   default: {}
      attribute :cookbook_versions,   type: Hash,   default: {}
    end

    has_many :cookbooks
    has_many :nodes
  end
end
