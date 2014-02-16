require 'spec_helper'

module ChefAPI
  describe Resource::Node do
    it_behaves_like 'a Chef API resource', :node,
      update: { chef_environment: 'my_environment' }
  end
end
