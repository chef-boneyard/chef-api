require 'spec_helper'

module ChefAPI
  describe Defaults do
    before(:each) do
      subject.instance_variable_set(:@config, nil)
    end

    context 'without a config file' do
      before(:each) do
        allow(subject).to receive(:config).and_return(Hash.new)
      end

      it 'returns the default endpoint' do
        expect(subject.endpoint).to eq subject::ENDPOINT
      end

      it 'returns the default user agent' do
        expect(subject.user_agent).to eq subject::USER_AGENT
      end
    end

    context 'without a config file and no ENV vars to find it' do
      around do |example|
        old_conf = ENV.delete('CHEF_API_CONFIG')
        old_home = ENV.delete('HOME')
        example.run
        ENV['CHEF_API_CONFIG'] = old_conf
        ENV['HOME'] = old_home
      end

      it 'returns the default without errors' do
        expect { subject.config }.not_to raise_error
      end

      it 'returns the default which is the empty hash' do
        expect(subject.config).to eq({})
      end
    end

    context 'with a config file' do
      before(:each) do
        config_content = "{\n"\
            "\"CHEF_API_ENDPOINT\": \"test_endpoint\",\n" \
            "\"CHEF_API_USER_AGENT\": \"test_user_agent\"\n" \
            "}"
        path = instance_double(Pathname, read: config_content, exist?: true)
        allow(subject).to receive(:config_path).and_return(path)
      end

      it 'returns the overridden value for endpoint' do
        expect(subject.endpoint).to eq 'test_endpoint'
      end

      it 'returns the overridden value for user agent' do
        expect(subject.user_agent).to eq 'test_user_agent'
      end
    end
  end
end
