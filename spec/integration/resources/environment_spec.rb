require 'spec_helper'

module ChefAPI
  describe Resource::Environment do
    it_behaves_like 'a Chef API resource', :environment,
      update: { description: 'This is the new description' }
  end
end
