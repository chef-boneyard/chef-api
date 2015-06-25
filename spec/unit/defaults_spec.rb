require 'spec_helper'

module ChefAPI
  describe Defaults do
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

    context 'with a config file' do
      before(:each) do
        allow(File).to receive(:read).and_return("{\n"\
            "\"CHEF_API_ENDPOINT\": \"test_endpoint\",\n" \
            "\"CHEF_API_USER_AGENT\": \"test_user_agent\"\n" \
            "}"
        )
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
