module ChefAPI
  class Resource::Client < Resource::Base
    collection_name :clients

    schema do
      attribute :name,       type: String,  primary: true
                                            required: true
      attribute :admin,      type: Boolean, default: false
      attribute :public_key, type: String
      attribute :validator,  type: Boolean
    end
  end
end
