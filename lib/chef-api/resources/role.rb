module ChefAPI
  class Resource::Role < Resource::Base
    collection_name :roles

    schema do
      attribute :name,                type: String, primary: true,
                                                    required: true
      attribute :description,         type: String
      attribute :default_attributes,  type: Hash,   default: {}
      attribute :override_attributes, type: Hash,   default: {}
      attribute :run_list,            type: Array,  default: []
      attribute :env_run_lists,       type: Hash,   default: {}
    end
  end
end
