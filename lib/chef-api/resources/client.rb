module ChefAPI
  class Resource::Client < Resource::Base
    collection_path '/clients'

    schema do
      attribute :name,        type: String,  primary: true, required: true
      attribute :admin,       type: Boolean, default: false
      attribute :public_key,  type: String
      attribute :private_key, type: [String, Boolean], default: false
      attribute :validator,   type: Boolean, default: false

      ignore :certificate, :clientname, :orgname
    end

    # @todo implement
    protect 'chef-webui', 'chef-validator'

    class << self
      #
      # Load the client from a .pem file on disk. Lots of assumptions are made
      # here.
      #
      # @param [String] path
      #   the path to the client on disk
      #
      # @return [Resource::Client]
      #
      def from_file(path)
        name, key = Util.safe_read(path)

        if client = fetch(name)
          client.private_key = key
          client
        else
          new(name: name, private_key: key)
        end
      end
    end

    #
    # Override the loading of the client. Since HEC and EC both return
    # +certificate+, but OPC and CZ both use +public_key+. In order to
    # normalize this discrepancy, the intializer converts the response from
    # the server OPC format. HEC and EC both handle putting a public key to
    # the server instead of a certificate.
    #
    # @see Resource::Base#initialize
    #
    def initialize(attributes = {}, prefix = {})
      if certificate = attributes.delete(:certificate) ||
                       attributes.delete('certificate')
        x509 = OpenSSL::X509::Certificate.new(certificate)
        attributes[:public_key] = x509.public_key.to_pem
      end

      super
    end

    #
    # Generate a new RSA private key for this API client.
    #
    # @example Regenerate the private key
    #   key = client.regenerate_key
    #   key #=> "-----BEGIN PRIVATE KEY-----\nMIGfMA0GCS..."
    #
    # @note For security reasons, you should perform this operation sparingly!
    #   The resulting private key is committed to this object, meaning it is
    #   saved to memory somewhere. You should set this resource's +private_key+
    #   to +nil+ after you have committed it to disk and perform a manual GC to
    #   be ultra-secure.
    #
    # @note Regenerating the private key also regenerates the public key!
    #
    # @return [self]
    #   the current resource with the new public and private key attributes
    #
    def regenerate_keys
      raise Error::CannotRegenerateKey if new_resource?
      update(private_key: true).save!
      self
    end
  end
end
