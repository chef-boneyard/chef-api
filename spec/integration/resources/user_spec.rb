require 'spec_helper'

module ChefAPI
  describe Resource::User do
    it_behaves_like 'a Chef API resource', :user,
      update: { admin: true }
  end
end
