require 'spec_helper'

module ChefAPI
  describe Resource::PartialSearch do
    describe '.query' do
      it 'returns a partial search resource' do
        chef_server.send('create_client', 'bacon')
        results = described_class.query(:client, { name: ['name'] })
        expect(results).to be_a(described_class)
      end

      it 'returns partial data' do
        chef_server.send('create_node', 'bacon1', { foo: :bar })
        chef_server.send('create_node', 'bacon2', { foo: :baz, bar: :foo })
        keys = { data: ['bar'] }
        results = described_class.query(:node, keys, '*:*', start: 1)
        expect(results.total).to be == 2
        expect(results.rows.size).to be == 1
        expect(results.rows.first).to be == { 'data' => 'foo' }
      end
    end
  end
end
