require 'spec_helper'

module ChefAPI
  describe Authentication do
    let(:user)      { 'sethvargo' }
    let(:key)       { rspec_support_file('user.pem') }
    let(:body)      { nil }
    let(:verb)      { :get }
    let(:path)      { '/foo/bar' }
    let(:timestamp) { '1991-07-23T03:00:54Z' }

    let(:headers)   { described_class.new(user, key, verb, path, body).headers }

    before do
      allow(Time).to receive_message_chain(:now, :utc, :iso8601)
        .and_return(timestamp)
    end

    context 'when given a request with no body' do
      let(:body) { nil }

      it 'returns the signed headers' do
        expect(headers['X-Ops-Sign']).to eq('algorithm=sha1;version=1.0;')
        expect(headers['X-Ops-Userid']).to eq('sethvargo')
        expect(headers['X-Ops-Timestamp']).to eq('1991-07-23T03:00:54Z')
        expect(headers['X-Ops-Content-Hash']).to eq('2jmj7l5rSw0yVb/vlWAYkK/YBwk=')
        expect(headers['X-Ops-Authorization-1']).to eq('UuadIvkZTeZDcFW6oNilet0QzTcP/9JsRhSjIKCiZiqUeBG9jz4mU9w+TWsm')
        expect(headers['X-Ops-Authorization-2']).to eq('2R3IiEKOW0S+UZpN19tPZ3nTdUluEvguidnsjuM/UpHymgY7M560pN4idXt5')
        expect(headers['X-Ops-Authorization-3']).to eq('MQYAEHhFHTOfBX8ihOPkA5gkbLw6ehftjL10W/7H3bTrl1tiHHkv2Lmz4e+e')
        expect(headers['X-Ops-Authorization-4']).to eq('9dJNeNDYVEaR1Efj7B7rnKjSD6SvRdqq0gbwiTfE7P2B88yjnq+a9eEoYgG3')
        expect(headers['X-Ops-Authorization-5']).to eq('lmNnVT5pqJPHiE1YFj1OITywAi/5pMzJCzYzVyWxQT+4r+SIRtRESrRFi1Re')
        expect(headers['X-Ops-Authorization-6']).to eq('OfHqhynKfmxMHAxVLJbfdjH3yX8Z8bq3tGPbdXxYAw==')
      end
    end

    context 'when given a request with a string body' do
      let(:body) { '{ "some": { "json": true } }' }

      it 'returns the signed headers' do
        expect(headers['X-Ops-Sign']).to eq('algorithm=sha1;version=1.0;')
        expect(headers['X-Ops-Userid']).to eq('sethvargo')
        expect(headers['X-Ops-Timestamp']).to eq('1991-07-23T03:00:54Z')
        expect(headers['X-Ops-Content-Hash']).to eq('D3+ox1HKmuzp3SLWiSU/5RdnbdY=')
        expect(headers['X-Ops-Authorization-1']).to eq('fbV8dt51y832DJS0bfR1LJ+EF/HHiDEgqJawNZyKMkgMHZ0Bv78kQVtH73fS')
        expect(headers['X-Ops-Authorization-2']).to eq('s3JQkMpZOwsNO8n2iduexmTthJe/JXG4sUgBKkS2qtKxpBy5snFSb6wD5ZuC')
        expect(headers['X-Ops-Authorization-3']).to eq('VJuC1YpOF6bGM8CyUG0O0SZBZRFZVgyC5TFACJn8ymMIx0FznWSPLyvoSjsZ')
        expect(headers['X-Ops-Authorization-4']).to eq('pdVOjhPV2+EQaj3c01dBFx5FSXgnBhWSmu2DCel/74TDt5RBraPcB4wczwpz')
        expect(headers['X-Ops-Authorization-5']).to eq('VIeVqGMuQ71OE0tabej4OKyf1+BopOedxVH1+KF5ETisxqrNhmEtUY5WrmSS')
        expect(headers['X-Ops-Authorization-6']).to eq('hjhiBXFdieV24Sojq6PKBhEEwpJqrPVP1lZNkRXdoA==')
      end
    end

    context 'when given an IO object' do
      let(:body) { File.open(rspec_support_file('cookbook.tar.gz')) }

      it 'returns the signed headers' do
        expect(headers['X-Ops-Sign']).to eq('algorithm=sha1;version=1.0;')
        expect(headers['X-Ops-Userid']).to eq('sethvargo')
        expect(headers['X-Ops-Timestamp']).to eq('1991-07-23T03:00:54Z')
        expect(headers['X-Ops-Content-Hash']).to eq('AWFSGfxiL2XltqdgSKCpdm84H9o=')
        expect(headers['X-Ops-Authorization-1']).to eq('oRvANxtLQanzqdC28l0szONjTni9zLRBiybYNyxyxos7M1X3kSs5LknmMA/E')
        expect(headers['X-Ops-Authorization-2']).to eq('i6Izk87dCcG3LLiGqRh0x/BoayS9SyoctdfMRR5ivrKRUzuQU9elHRpXnmjw')
        expect(headers['X-Ops-Authorization-3']).to eq('7i/tlbLPrJQ/0+di9BU4m+BBD/vbh80KajmsaszxHx1wwNEBkNAymSLSDqXX')
        expect(headers['X-Ops-Authorization-4']).to eq('gVAjNiaEzV9/EPQyGAYaU40SOdDwKzBthxgCpM9sfpfQsXj4Oj4SvSmO+4sy')
        expect(headers['X-Ops-Authorization-5']).to eq('eJ0l7vpR0MyQqnhqbJHkQAGsG/HUhuhG0E9T7dClk08EB+sdsnDxr+5laei3')
        expect(headers['X-Ops-Authorization-6']).to eq('YtCw2spOnumfdqx2hWvLmxR3y2eOuLBv77tZXUQ4Ug==')
      end
    end
  end
end
