module ChefAPI
  class Resource::Node < Resource::Base
    collection_path '/nodes'

    schema do
      attribute :name,       type: String, primary: true, required: true
      attribute :automatic,  type: Hash,   default: {}
      attribute :default,    type: Hash,   default: {}
      attribute :normal,     type: Hash,   default: {}
      attribute :override,   type: Hash,   default: {}
      attribute :run_list,   type: Array,  default: []

      # Enterprise Chef attributes
      attribute :chef_environment, type: String, default: '_default'
    end
  end
end
