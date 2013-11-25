require 'spec_helper'

module ChefAPI
  describe Resource::Role do
    describe '.fetch' do
      it 'returns nil when the resource does not exist' do
        expect(described_class.fetch('not_real')).to be_nil
      end

      it 'returns the resource' do
        chef_server.create_role('bacon')
        expect(described_class.fetch('bacon').name).to eq('bacon')
      end
    end

    describe '.build' do
      it 'builds a resource' do
        instance = described_class.build(name: 'bacon')
        expect(instance).to be_a(described_class)
      end

      it 'does not create a remote resource' do
        described_class.build(name: 'bacon')
        expect(chef_server).to_not have_role('bacon')
      end
    end

    describe '.create' do
      it 'creates a new remote resource' do
        described_class.create(name: 'bacon')
        expect(chef_server).to have_role('bacon')
      end

      it 'raises an exception when the resource already exists' do
        chef_server.create_role('bacon')
        expect { described_class.create(name: 'bacon') }.to raise_error
      end
    end

    describe '.exists?' do
      it 'returns false when the resource does not exist' do
        expect(described_class.exists?('bacon')).to be_false
      end

      it 'returns true when the resource exists' do
        chef_server.create_role('bacon')
        expect(described_class.exists?('bacon')).to be_true
      end
    end

    describe '.update' do
      it 'updates an existing resource' do
        chef_server.create_role('bacon')
        description = 'This is a new description'

        described_class.update('bacon', { description: description })
        expect(chef_server.role('bacon')['description']).to eq(description)
      end

      it 'raises an exception when the resource does not exist' do
        expect { described_class.upate('bacon').to raise_error }
      end
    end

    describe '.delete' do
      it 'deletes an existing record' do
        chef_server.create_role('bacon')
        described_class.delete('bacon')
        expect(chef_server).to_not have_role('bacon')
      end

      it 'does not raise an exception if the record does not exist' do
        expect { described_class.delete('bacon') }.to_not raise_error
      end
    end

    describe '.count' do
      it 'returns the total number of resources' do
        5.times { |i| chef_server.create_role("role_#{i}") }
        expect(described_class.count).to eq(5)
      end
    end
  end
end
