require 'spec_helper'

module ChefAPI::Error
  describe ChefAPIError do
    let(:instance) { described_class.new }

    it 'raises an exception with the correct message' do
      expect { raise instance }.to raise_error { |error|
        expect(error).to be_a(described_class)
        expect(error.message).to eq <<-EOH.gsub(/^ {10}/, '')
          Oh no! Something really bad happened. I am not sure what actually happened because this is the catch-all error, but you should most definitely report an issue on GitHub at https://github.com/sethvargo/chef-api.
        EOH
      }
    end
  end

  describe AbstractMethod do
    let(:instance) { described_class.new(method: 'Resource#load') }

    it 'raises an exception with the correct message' do
      expect { raise instance }.to raise_error { |error|
        expect(error).to be_a(described_class)
        expect(error.message).to eq <<-EOH.gsub(/^ {10}/, '')
          'Resource#load' is an abstract method. You must override this method in your subclass with the proper implementation and logic. For more information, please see the inline documentation for Resource#load. If you are not a developer, this is most likely a bug in the ChefAPI gem. Please file a bug report at:

              https://github.com/sethvargo/chef-api/issues/new

          and include the command(s) or code you ran to arrive at this error.
        EOH
      }
    end
  end

  describe CannotRegenerateKey do
    let(:instance) { described_class.new }

    it 'raises an exception with the correct message' do
      expect { raise instance }.to raise_error { |error|
        expect(error).to be_a(described_class)
        expect(error.message).to eq <<-EOH.gsub(/^ {10}/, '')
          You attempted to regenerate the private key for a Client or User that does not yet exist on the remote Chef Server. You can only regenerate the key for an object that is persisted. Try saving this record this object before regenerating the key.
        EOH
      }
    end
  end

  describe FileNotFound do
    let(:instance) { described_class.new(path: '/path/to/file.rb') }

    it 'raises an exception with the correct message' do
      expect { raise instance }.to raise_error { |error|
        expect(error).to be_a(described_class)
        expect(error.message).to eq <<-EOH.gsub(/^ {10}/, '')
          I could not find a file at '/path/to/file.rb'. Please make sure you have typed the path correctly and that the resource exists at the given path.
        EOH
      }
    end
  end

  describe HTTPBadRequest do
    let(:instance) { described_class.new(message: 'Something happened...') }

    it 'raises an exception with the correct message' do
      expect { raise instance }.to raise_error { |error|
        expect(error).to be_a(described_class)
        expect(error.message).to eq <<-EOH.gsub(/^ {10}/, '')
          The Chef Server did not understand the request because it was malformed.

              Something happened...
        EOH
      }
    end
  end

  describe HTTPForbiddenRequest do
    let(:instance) { described_class.new(message: 'Something happened...') }

    it 'raises an exception with the correct message' do
      expect { raise instance }.to raise_error { |error|
        expect(error).to be_a(described_class)
        expect(error.message).to eq <<-EOH.gsub(/^ {10}/, '')
          The Chef Server actively refused to fulfill the request.

              Something happened...
        EOH
      }
    end
  end

  describe HTTPGatewayTimeout do
    let(:instance) { described_class.new(message: 'Something happened...') }

    it 'raises an exception with the correct message' do
      expect { raise instance }.to raise_error { |error|
        expect(error).to be_a(described_class)
        expect(error.message).to eq <<-EOH.gsub(/^ {10}/, '')
          The Chef Server did not respond in an adequate amount of time.

              Something happened...
        EOH
      }
    end
  end

  describe HTTPMethodNotAllowed do
    let(:instance) { described_class.new(message: 'Something happened...') }

    it 'raises an exception with the correct message' do
      expect { raise instance }.to raise_error { |error|
        expect(error).to be_a(described_class)
        expect(error.message).to eq <<-EOH.gsub(/^ {10}/, '')
          That HTTP method is not allowed on this URL.

              Something happened...
        EOH
      }
    end
  end

  describe HTTPNotAcceptable do
    let(:instance) { described_class.new(message: 'Something happened...') }

    it 'raises an exception with the correct message' do
      expect { raise instance }.to raise_error { |error|
        expect(error).to be_a(described_class)
        expect(error.message).to eq <<-EOH.gsub(/^ {10}/, '')
          The Chef Server identified this request as unacceptable. This usually means you have not specified the correct Accept or Content-Type headers on the request.

              Something happened...
        EOH
      }
    end
  end

  describe HTTPNotFound do
    let(:instance) { described_class.new(message: 'Something happened...') }

    it 'raises an exception with the correct message' do
      expect { raise instance }.to raise_error { |error|
        expect(error).to be_a(described_class)
        expect(error.message).to eq <<-EOH.gsub(/^ {10}/, '')
          The requested URL does not exist on the Chef Server.

              Something happened...
        EOH
      }
    end
  end

  describe HTTPServerUnavailable do
    let(:instance) { described_class.new }

    it 'raises an exception with the correct message' do
      expect { raise instance }.to raise_error { |error|
        expect(error).to be_a(described_class)
        expect(error.message).to eq <<-EOH.gsub(/^ {10}/, '')
          The Chef Server is currently unavailable or is not currently accepting client connections. Please ensure the server is accessible via ping or telnet on your local network. If this error persists, please contact your network administrator.
        EOH
      }
    end
  end

  describe HTTPUnauthorizedRequest do
    let(:instance) { described_class.new(message: 'Something happened...') }

    it 'raises an exception with the correct message' do
      expect { raise instance }.to raise_error { |error|
        expect(error).to be_a(described_class)
        expect(error.message).to eq <<-EOH.gsub(/^ {10}/, '')
          The Chef Server requires authorization. Please ensure you have specified the correct client name and private key. If this error continues, please verify the given client has the proper permissions on the Chef Server.

              Something happened...
        EOH
      }
    end
  end

  describe InsufficientFilePermissions do
    let(:instance) { described_class.new(path: '/path/to/file.rb') }

    it 'raises an exception with the correct message' do
      expect { raise instance }.to raise_error { |error|
        expect(error).to be_a(described_class)
        expect(error.message).to eq <<-EOH.gsub(/^ {10}/, '')
          I cannot read the file at '/path/to/file.rb' because the permissions on the file do not permit it. Please ensure the file has the correct permissions and that this Ruby process is running as a user with access to that path.
        EOH
      }
    end
  end

  describe InvalidResource do
    let(:instance) { described_class.new(errors: 'Missing a thing!') }

    it 'raises an exception with the correct message' do
      expect { raise instance }.to raise_error { |error|
        expect(error).to be_a(described_class)
        expect(error.message).to eq <<-EOH.gsub(/^ {10}/, '')
          There were errors saving your resource: Missing a thing!
        EOH
      }
    end
  end

  describe InvalidValidator do
    let(:instance) { described_class.new(key: 'bacon') }

    it 'raises an exception with the correct message' do
      expect { raise instance }.to raise_error { |error|
        expect(error).to be_a(described_class)
        expect(error.message).to eq <<-EOH.gsub(/^ {10}/, '')
          'bacon' is not a valid validator. Please make sure it is spelled correctly and that the constant is properly defined. If you are using a custom validator, please ensure the validator extends ChefAPI::Validator::Base and is a subclass of ChefAPI::Validator.
        EOH
      }
    end
  end

  describe MissingURLParameter do
    let(:instance) { described_class.new(param: 'user') }

    it 'raises an exception with the correct message' do
      expect { raise instance }.to raise_error { |error|
        expect(error).to be_a(described_class)
        expect(error.message).to eq <<-EOH.gsub(/^ {10}/, '')
          The required URL parameter 'user' was not present. Please specify the parameter as an option, like Resource.new(id, user: 'value').
        EOH
      }
    end
  end

  describe NotADirectory do
    let(:instance) { described_class.new(path: '/path/to/directory') }

    it 'raises an exception with the correct message' do
      expect { raise instance }.to raise_error { |error|
        expect(error).to be_a(described_class)
        expect(error.message).to eq <<-EOH.gsub(/^ {10}/, '')
          The given path '/path/to/directory' is not a directory. Please make sure you have passed the path to a directory on disk.
        EOH
      }
    end
  end

  describe ResourceAlreadyExists do
    let(:instance) { described_class.new(type: 'client', id: 'bacon') }

    it 'raises an exception with the correct message' do
      expect { raise instance }.to raise_error { |error|
        expect(error).to be_a(described_class)
        expect(error.message).to eq <<-EOH.gsub(/^ {10}/, '')
          The client 'bacon' already exists on the Chef Server. Each client must have a unique identifier and the Chef Server indicated this client already exists. If you are trying to update the client, consider using the 'update' method instead.
        EOH
      }
    end
  end

  describe ResourceNotFound do
    let(:instance) { described_class.new(type: 'client', id: 'bacon') }

    it 'raises an exception with the correct message' do
      expect { raise instance }.to raise_error { |error|
        expect(error).to be_a(described_class)
        expect(error.message).to eq <<-EOH.gsub(/^ {10}/, '')
          There is no client with an id of 'bacon' on the Chef Server. If you are updating the client, please make sure the client exists and has the correct Chef identifier (primary key).
        EOH
      }
    end
  end

  describe ResourceNotMutable do
    let(:instance) { described_class.new(type: 'client', id: 'bacon') }

    it 'raises an exception with the correct message' do
      expect { raise instance }.to raise_error { |error|
        expect(error).to be_a(described_class)
        expect(error.message).to eq <<-EOH.gsub(/^ {10}/, '')
          The client 'bacon' is not mutable. It may be locked by the remote Chef Server, or the Chef Server may not permit modifying the resource.
        EOH
      }
    end
  end

  describe UnknownAttribute do
    let(:instance) { described_class.new(attribute: 'name') }

    it 'raises an exception with the correct message' do
      expect { raise instance }.to raise_error { |error|
        expect(error).to be_a(described_class)
        expect(error.message).to eq <<-EOH.gsub(/^ {10}/, '')
          'name' is not a valid attribute!
        EOH
      }
    end
  end
end
