require 'spec_helper'

module ChefAPI
  describe Resource::Client do
    it_behaves_like 'a Chef API resource', :client,
      update: { validator: true }
  end
end
