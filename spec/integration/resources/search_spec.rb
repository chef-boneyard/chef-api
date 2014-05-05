require 'spec_helper'

module ChefAPI
  describe Resource::Search do
    describe '.query' do
      it 'returns a search resource' do
        chef_server.send('create_client', 'bacon')
        results = described_class.query(:client)
        expect(results).to be_a(described_class)
      end

      it 'options are passed to the chef-server' do
        chef_server.send('create_node', 'bacon1', { foo: :bar })
        chef_server.send('create_node', 'bacon2', { foo: :baz })
        results = described_class.query(:node, '*:*', start: 1)
        expect(results.total).to be == 2
        expect(results.rows.size).to be == 1
      end
    end
  end
end
