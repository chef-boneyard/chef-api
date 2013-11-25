require 'spec_helper'

module ChefAPI
  describe Resource::Client do
    describe '.primary_key' do
      its(:primary_key) { should eq(:id) }
    end
  end
end
