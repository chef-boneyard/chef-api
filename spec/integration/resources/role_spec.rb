require 'spec_helper'

module ChefAPI
  describe Resource::Role do
    it_behaves_like 'a Chef API resource', :role,
      update: { description: 'This is the new description' }
  end
end
