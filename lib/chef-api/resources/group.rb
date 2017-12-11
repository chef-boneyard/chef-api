module ChefAPI
  class Resource::Group < Resource::Base
    collection_path '/groups'

    schema do
      attribute :groupname, type: String, primary: true, required: true
      attribute :name,      type: String
      attribute :orgname,   type: String
      attribute :actors,    type: Array, default: []
      attribute :users,     type: Array, default: []
      attribute :clients,   type: Array, default: []
      attribute :groups,    type: Array, default: []
    end
  end
end

