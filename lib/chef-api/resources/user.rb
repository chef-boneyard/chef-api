module ChefAPI
  class Resource::User < Resource::Base
    collection_path '/users'

    schema do
      attribute :name,        type: String,  primary: true, required: true
      attribute :admin,       type: Boolean, default: false
      attribute :public_key,  type: String
    end
  end
end
