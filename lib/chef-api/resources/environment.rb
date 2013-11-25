module ChefAPI
  class Resource::Environment < Resource::Base
    collection_name :environments

    schema do
      attribute :name,                type: String, primary: true,
                                                    required: true
      attribute :description,         type: String
      attribute :default_attributes,  type: String, default: {}
      attribute :override_attributes, type: String, default: {}
      attribute :cookbook_versions,   type: String, default: {}
    end
  end
end
