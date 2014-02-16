require 'spec_helper'

module ChefAPI
  describe Resource::Client do
    shared_examples_for 'a Chef API resource' do |type|
      describe '.destroy' do
        let(:resource_id) { "bacon_#{type}" }

        it "destroys the #{type} with the given ID" do
          chef_server.send("create_#{type}", resource_id)
          described_class.delete(resource_id)

          expect(chef_server).to_not send("have_#{type}", resource_id)
        end

        it 'does not raise an exception if the record does not exist' do
          expect { described_class.delete('bacon') }.to_not raise_error
        end
      end
    end

    it_behaves_like 'a Chef API resource', :client

    describe '.fetch' do
      it 'returns nil when the resource does not exist' do
        expect(described_class.fetch('not_real')).to be_nil
      end

      it 'returns the resource' do
        chef_server.create_client('bacon')
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
        expect(chef_server).to_not have_client('bacon')
      end
    end

    describe '.create' do
      it 'creates a new remote resource' do
        described_class.create(name: 'bacon')
        expect(chef_server).to have_client('bacon')
      end

      it 'raises an exception when the resource already exists' do
        chef_server.create_client('bacon')
        expect {
          described_class.create(name: 'bacon')
        }.to raise_error(Error::ResourceAlreadyExists)
      end
    end

    describe '.exists?' do
      it 'returns false when the resource does not exist' do
        expect(described_class.exists?('bacon')).to be_false
      end

      it 'returns true when the resource exists' do
        chef_server.create_client('bacon')
        expect(described_class.exists?('bacon')).to be_true
      end
    end

    describe '.update' do
      it 'updates an existing resource' do
        chef_server.create_client('bacon')
        public_key = OpenSSL::PKey::RSA.generate(1).to_pem

        described_class.update('bacon', { public_key: public_key })
        expect(chef_server.client('bacon')['public_key']).to eq(public_key)
      end

      it 'raises an exception when the resource does not exist' do
        expect { described_class.upate('bacon').to raise_error }
      end
    end

    describe '.count' do
      it 'returns the total number of resources' do
        5.times { |i| chef_server.create_client("client_#{i}") }
        expect(described_class.count).to eq(7) # validator and web-ui + n
      end
    end
  end
end
