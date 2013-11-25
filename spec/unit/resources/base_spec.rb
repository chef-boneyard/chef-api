require 'spec_helper'

module ChefAPI
  describe Resource::Base do
    before do
      # Unset all instance variables (which are actually cached on the parent
      # class) to prevent caching.
      described_class.instance_variables.each do |instance_variable|
        described_class.send(:remove_instance_variable, instance_variable)
      end
    end

    describe '.schema' do
      it 'sets the schema for the class' do
        block = Proc.new {}
        described_class.schema(&block)
        expect(described_class.schema).to be_a(Schema)
      end
    end

    describe '.collection_path' do
      it 'raises an exception if the collection name is not set' do
        expect { described_class.collection_path }.to raise_error
      end

      it 'sets the collection name' do
        described_class.collection_path('bacons')
        expect(described_class.collection_path).to eq('bacons')
      end

      it 'converts the symbol to a string' do
        described_class.collection_path(:bacons)
        expect(described_class.collection_path).to eq('bacons')
      end
    end

    describe '.build' do
      it 'creates a new instance' do
        described_class.stub(:new)

        expect(described_class).to receive(:new).with(foo: 'bar')
        described_class.build(foo: 'bar')
      end
    end
  end
end
