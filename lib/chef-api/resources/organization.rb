module ChefAPI
  class Resource::Organization < Resource::Base
    collection_path '/organizations'

    schema do
      attribute :name,       type: String, primary: true, required: true
      attribute :org_type,   type: String
      attribute :full_name,  type: String
      attribute :clientname, type: String
      attribute :guid,       type: String

      ignore :_id
      ignore :_rev
      ignore :chargify_subscription_id
      ignore :chargify_customer_id
      ignore :billing_plan
      ignore :requester_id
      ignore :assigned_at
      ignore 'couchrest-type'
    end
  end
end
