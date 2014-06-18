shared_examples_for 'a Chef API resource' do |type, options = {}|
  let(:resource_id) { "my_#{type}" }

  describe '.fetch' do
    it 'returns nil when the resource does not exist' do
      expect(described_class.fetch('not_real')).to be_nil
    end

    it 'returns the resource' do
      chef_server.send("create_#{type}", resource_id)
      expect(described_class.fetch(resource_id).name).to eq(resource_id)
    end
  end

  describe '.build' do
    it 'builds a resource' do
      instance = described_class.build(name: resource_id)
      expect(instance).to be_a(described_class)
    end

    it 'does not create a remote resource' do
      described_class.build(name: resource_id)
      expect(chef_server).to_not send("have_#{type}", resource_id)
    end
  end

  describe '.create' do
    it 'creates a new remote resource' do
      described_class.create(name: resource_id)
      expect(chef_server).to send("have_#{type}", resource_id)
    end

    it 'raises an exception when the resource already exists' do
      chef_server.send("create_#{type}", resource_id)
      expect {
        described_class.create(name: resource_id)
      }.to raise_error(ChefAPI::Error::ResourceAlreadyExists)
    end
  end

  describe '.exists?' do
    it 'returns false when the resource does not exist' do
      expect(described_class.exists?(resource_id)).to be_falsey
    end

    it 'returns true when the resource exists' do
      chef_server.send("create_#{type}", resource_id)
      expect(described_class.exists?(resource_id)).to be_truthy
    end
  end

  describe '.destroy' do
    it "destroys the #{type} with the given ID" do
      chef_server.send("create_#{type}", resource_id)
      described_class.delete(resource_id)

      expect(chef_server).to_not send("have_#{type}", resource_id)
    end

    it 'does not raise an exception if the record does not exist' do
      expect { described_class.delete(resource_id) }.to_not raise_error
    end
  end

  describe '.update' do
    it 'updates an existing resource' do
      chef_server.send("create_#{type}", resource_id)

      options[:update].each do |key, value|
        described_class.update(resource_id, key => value)
        expect(chef_server.send(type, resource_id)[key.to_s]).to eq(value)
      end
    end

    it 'raises an exception when the resource does not exist' do
      expect {
        described_class.update(resource_id)
      }.to raise_error(ChefAPI::Error::ResourceNotFound)
    end
  end

  describe '.count' do
    it 'returns the total number of resources' do
      5.times do |i|
        chef_server.send("create_#{type}", "#{resource_id}_#{i}")
      end

      expect(described_class.count).to be >= 5
    end
  end
end
