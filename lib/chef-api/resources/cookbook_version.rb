module ChefAPI
  class Resource::CookbookVersion < Resource::Base
    collection_path '/cookbooks/:cookbook'

    schema do
      attribute :name,          type: String,  primary: true, required: true
      attribute :cookbook_name, type: String,  required: true
      attribute :metadata,      type: Hash,    required: true
      attribute :version,       type: String,  required: true
      attribute :frozen?,       type: Boolean, default: false

      attribute :attributes,  type: Array, default: []
      attribute :definitions, type: Array, default: []
      attribute :files,       type: Array, default: []
      attribute :libraries,   type: Array, default: []
      attribute :providers,   type: Array, default: []
      attribute :recipes,     type: Array, default: []
      attribute :resources,   type: Array, default: []
      attribute :root_files,  type: Array, default: []
      attribute :templates,   type: Array, default: []
    end
  end
end
