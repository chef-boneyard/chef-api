require 'spec_helper'

module ChefAPI
  describe Connection do
    shared_examples 'a proxy for' do |resource, klass|
      context "##{resource}" do
        it 'sets Thread.current to self' do
          subject.send(resource)
          expect(Thread.current['chefapi.connection']).to be(subject)
        end

        it "returns an instance of #{klass}" do
          # Fuck you Ruby 1.9.3
          expected = klass.split('::').inject(ChefAPI) { |c, i| c.const_get(i) }

          expect(subject.send(resource)).to be(expected)
        end
      end
    end

    it_behaves_like 'a proxy for', :clients,        'Resource::Client'
    it_behaves_like 'a proxy for', :data_bags,      'Resource::DataBag'
    it_behaves_like 'a proxy for', :environments,   'Resource::Environment'
    it_behaves_like 'a proxy for', :nodes,          'Resource::Node'
    it_behaves_like 'a proxy for', :partial_search, 'Resource::PartialSearch'
    it_behaves_like 'a proxy for', :principals,     'Resource::Principal'
    it_behaves_like 'a proxy for', :roles,          'Resource::Role'
    it_behaves_like 'a proxy for', :search,         'Resource::Search'
    it_behaves_like 'a proxy for', :users,          'Resource::User'

    context '#initialize' do
      context 'when options are given' do
        let(:endpoint) { 'http://endpoint.gov' }

        it 'sets the option' do
          instance = described_class.new(endpoint: endpoint)
          expect(instance.endpoint).to eq(endpoint)
        end

        it 'uses the default options' do
          instance = described_class.new
          expect(instance.endpoint).to eq(ChefAPI.endpoint)
        end
      end

      context 'when a block is given' do
        it 'yields self' do
          expect { |b| described_class.new(&b) }.to yield_with_args(described_class)
        end
      end
    end
  end
end
