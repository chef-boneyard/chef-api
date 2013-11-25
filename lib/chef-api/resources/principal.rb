module ChefAPI
  class Resource::Principal < Resource::Base
    collection_path '/principals'

    schema do
      attribute :name,       type: String, primary: true, required: true
      attribute :type,       type: String
      attribute :public_key, type: String
    end
  end
end
