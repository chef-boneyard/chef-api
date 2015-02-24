module ChefAPI
  class Resource::Base
    class << self
      # Including the Enumberable module gives us magic
      include Enumerable

      #
      # Load the given resource from it's on-disk equivalent. This action only
      # makes sense for some resources, and must be defined on a per-resource
      # basis, since the logic varies between resources.
      #
      # @param [String] path
      #   the path to the file on disk
      #
      def from_file(path)
        raise Error::AbstractMethod.new(method: 'Resource::Base#from_file')
      end

      #
      # @todo doc
      #
      def from_url(url, prefix = {})
        from_json(connection.get(url), prefix)
      end

      #
      # Get or set the schema for the remote resource. You probably only want
      # to call schema once with a block, because it will overwrite the
      # existing schema (meaning entries are not merged). If a block is given,
      # a new schema object is created, otherwise the current one is returned.
      #
      # @example
      #   schema do
      #     attribute :id, primary: true
      #     attribute :name, type: String, default: 'bacon'
      #     attribute :admin, type: Boolean, required: true
      #   end
      #
      # @return [Schema]
      #   the schema object for this resource
      #
      def schema(&block)
        if block
          @schema = Schema.new(&block)
        else
          @schema
        end
      end

      #
      # Protect one or more resources from being altered by the user. This is
      # useful if there's an admin client or magical cookbook that you don't
      # want users to modify.
      #
      # @example
      #   protect 'chef-webui', 'my-magical-validator'
      #
      # @example
      #   protect ->(resource) { resource.name =~ /internal_(.+)/ }
      #
      # @param [Array<String, Proc>] ids
      #   the list of "things" to protect
      #
      def protect(*ids)
        ids.each { |id| protected_resources << id }
      end

      #
      # Create a nested relationship collection. The associated collection
      # is cached on the class, reducing API requests.
      #
      # @example Create an association to environments
      #
      #   has_many :environments
      #
      # @example Create an association with custom configuration
      #
      #   has_many :environments, class_name: 'Environment'
      #
      def has_many(method, options = {})
        class_name    = options[:class_name] || "Resource::#{Util.camelize(method).sub(/s$/, '')}"
        rest_endpoint = options[:rest_endpoint] || method

        class_eval <<-EOH, __FILE__, __LINE__ + 1
          def #{method}
            associations[:#{method}] ||=
              Resource::CollectionProxy.new(self, #{class_name}, '#{rest_endpoint}')
          end
        EOH
      end

      #
      # @todo doc
      #
      def protected_resources
        @protected_resources ||= []
      end

      #
      # Get or set the name of the remote resource collection. This is most
      # likely the remote API endpoint (such as +/clients+), without the
      # leading slash.
      #
      # @example Setting a base collection path
      #   collection_path '/clients'
      #
      # @example Setting a collection path with nesting
      #   collection_path '/data/:name'
      #
      # @param [Symbol] value
      #   the value to use for the collection name.
      #
      # @return [Symbol, String]
      #   the name of the collection
      #
      def collection_path(value = UNSET)
        if value != UNSET
          @collection_path = value.to_s
        else
          @collection_path ||
            raise(ArgumentError, "collection_path not set for #{self.class}")
        end
      end

      #
      # Make an authenticated HTTP POST request using the connection object.
      # This method returns a new object representing the response from the
      # server, which should be merged with an existing object's attributes to
      # reflect the newest state of the resource.
      #
      # @param [Hash] body
      #   the request body to create the resource with (probably JSON)
      # @param [Hash] prefix
      #   the list of prefix options (for nested resources)
      #
      # @return [String]
      #   the JSON response from the server
      #
      def post(body, prefix = {})
        path = expanded_collection_path(prefix)
        connection.post(path, body)
      end

      #
      # Perform a PUT request to the Chef Server against the given resource or
      # resource identifier. The resource will be partially updated (this
      # method doubles as PATCH) with the given parameters.
      #
      # @param [String, Resource::Base] id
      #   a resource object or a string representing the unique identifier of
      #   the resource object to update
      # @param [Hash] body
      #   the request body to create the resource with (probably JSON)
      # @param [Hash] prefix
      #   the list of prefix options (for nested resources)
      #
      # @return [String]
      #   the JSON response from the server
      #
      def put(id, body, prefix = {})
        path = resource_path(id, prefix)
        connection.put(path, body)
      end

      #
      # Delete the remote resource from the Chef Sserver.
      #
      # @param [String, Fixnum] id
      #   the id of the resource to delete
      # @param [Hash] prefix
      #   the list of prefix options (for nested resources)
      # @return [true]
      #
      def delete(id, prefix = {})
        path = resource_path(id, prefix)
        connection.delete(path)
        true
      rescue Error::HTTPNotFound
        true
      end

      #
      # Get the "list" of items in this resource. This list contains the
      # primary keys of all of the resources in this collection. This method
      # is useful in CLI applications, because it only makes a single API
      # request to gather this data.
      #
      # @param [Hash] prefix
      #   the listof prefix options (for nested resources)
      #
      # @example Get the list of all clients
      #   Client.list #=> ['validator', 'chef-webui']
      #
      # @return [Array<String>]
      #
      def list(prefix = {})
        path = expanded_collection_path(prefix)
        connection.get(path).keys.sort
      end

      #
      # Destroy a record with the given id.
      #
      # @param [String, Fixnum] id
      #   the id of the resource to delete
      # @param [Hash] prefix
      #   the list of prefix options (for nested resources)
      #
      # @return [Base, nil]
      #   the destroyed resource, or nil if the resource does not exist on the
      #   remote Chef Server
      #
      def destroy(id, prefix = {})
        resource = fetch(id, prefix)
        return nil if resource.nil?

        resource.destroy
        resource
      end

      #
      # Delete all remote resources of the given type from the Chef Server
      #
      # @param [Hash] prefix
      #   the list of prefix options (for nested resources)
      # @return [Array<Base>]
      #   an array containing the list of resources that were deleted
      #
      def destroy_all(prefix = {})
        map { |resource| resource.destroy }
      end

      #
      # Fetch a single resource in the remote collection.
      #
      # @example fetch a single client
      #   Client.fetch('chef-webui') #=> #<Client name: 'chef-webui', ...>
      #
      # @param [String, Fixnum] id
      #   the id of the resource to fetch
      # @param [Hash] prefix
      #   the list of prefix options (for nested resources)
      #
      # @return [Resource::Base, nil]
      #   an instance of the resource, or nil if that given resource does not
      #   exist
      #
      def fetch(id, prefix = {})
        return nil if id.nil?

        path     = resource_path(id, prefix)
        response = connection.get(path)
        from_json(response, prefix)
      rescue Error::HTTPNotFound
        nil
      end

      #
      # Build a new resource from the given attributes.
      #
      # @see ChefAPI::Resource::Base#initialize for more information
      #
      # @example build an empty resource
      #   Bacon.build #=> #<ChefAPI::Resource::Bacon>
      #
      # @example build a resource with attributes
      #   Bacon.build(foo: 'bar') #=> #<ChefAPI::Resource::Baocn foo: bar>
      #
      # @param [Hash] attributes
      #   the list of attributes for the new resource - any attributes that
      #   are not defined in the schema are silently ignored
      #
      def build(attributes = {}, prefix = {})
        new(attributes, prefix)
      end

      #
      # Create a new resource and save it to the Chef Server, raising any
      # exceptions that might occur. This method will save the resource back to
      # the Chef Server, raising any validation errors that occur.
      #
      # @raise [Error::ResourceAlreadyExists]
      #   if the resource with the primary key already exists on the Chef Server
      # @raise [Error::InvalidResource]
      #   if any of the resource's validations fail
      #
      # @param [Hash] attributes
      #   the list of attributes to set on the new resource
      #
      # @return [Resource::Base]
      #   an instance of the created resource
      #
      def create(attributes = {}, prefix = {})
        resource = build(attributes, prefix)

        unless resource.new_resource?
          raise Error::ResourceAlreadyExists.new
        end

        resource.save!
        resource
      end

      #
      # Check if the given resource exists on the Chef Server.
      #
      # @param [String, Fixnum] id
      #   the id of the resource to fetch
      # @param [Hash] prefix
      #   the list of prefix options (for nested resources)
      #
      # @return [Boolean]
      #
      def exists?(id, prefix = {})
        !fetch(id, prefix).nil?
      end

      #
      # Perform a PUT request to the Chef Server for the current resource,
      # updating the given parameters. The parameters may be a full or
      # partial resource update, as supported by the Chef Server.
      #
      # @raise [Error::ResourceNotFound]
      #   if the given resource does not exist on the Chef Server
      #
      # @param [String, Fixnum] id
      #   the id of the resource to update
      # @param [Hash] attributes
      #   the list of attributes to set on the new resource
      # @param [Hash] prefix
      #   the list of prefix options (for nested resources)
      #
      # @return [Resource::Base]
      #   the new resource
      #
      def update(id, attributes = {}, prefix = {})
        resource = fetch(id, prefix)

        unless resource
          raise Error::ResourceNotFound.new(type: type, id: id)
        end

        resource.update(attributes).save
        resource
      end

      #
      # (Lazy) iterate over each item in the collection, yielding the fully-
      # built resource object. This method, coupled with the Enumerable
      # module, provides us with other methods like +first+ and +map+.
      #
      # @example get the first resource
      #   Bacon.first #=> #<ChefAPI::Resource::Bacon>
      #
      # @example get the first 3 resources
      #   Bacon.first(3) #=> [#<ChefAPI::Resource::Bacon>, ...]
      #
      # @example iterate over each resource
      #   Bacon.each { |bacon| puts bacon.name }
      #
      # @example get all the resource's names
      #   Bacon.map(&:name) #=> ["ham", "sausage", "turkey"]
      #
      def each(prefix = {}, &block)
        collection(prefix).each do |resource, path|
          response = connection.get(path)
          result = from_json(response, prefix)

          block.call(result) if block
        end
      end

      #
      # The total number of reosurces in the collection.
      #
      # @return [Fixnum]
      #
      def count(prefix = {})
        collection(prefix).size
      end
      alias_method :size, :count

      #
      # Return an array of all resources in the collection.
      #
      # @note Unless you need the _entire_ collection, please consider using the
      # {size} and {each} methods instead as they are much more perforant.
      #
      # @return [Array<Resource::Base>]
      #
      def all
        entries
      end

      #
      # Construct the object from a JSON response. This method actually just
      # delegates to the +new+ method, but it removes some marshall data and
      # whatnot from the response first.
      #
      # @param [String] response
      #   the JSON response from the Chef Server
      #
      # @return [Resource::Base]
      #   an instance of the resource represented by this JSON
      #
      def from_json(response, prefix = {})
        response.delete('json_class')
        response.delete('chef_type')

        new(response, prefix)
      end

      #
      # The string representation of this class.
      #
      # @example for the Bacon class
      #   Bacon.to_s #=> "Resource::Bacon"
      #
      # @return [String]
      #
      def to_s
        classname
      end

      #
      # The detailed string representation of this class, including the full
      # schema definition.
      #
      # @example for the Bacon class
      #   Bacon.inspect #=> "Resource::Bacon(id, description, ...)"
      #
      # @return [String]
      #
      def inspect
        "#{classname}(#{schema.attributes.keys.join(', ')})"
      end

      #
      # The name for this resource, minus the parent module.
      #
      # @example
      #   classname #=> Resource::Bacon
      #
      # @return [String]
      #
      def classname
        name.split('::')[1..-1].join('::')
      end

      #
      # The type of this resource.
      #
      # @example
      #   bacon
      #
      # @return [String]
      #
      def type
        Util.underscore(name.split('::').last).gsub('_', ' ')
      end

      #
      # The full collection list.
      #
      # @param [Hash] prefix
      #   any prefix options to use
      #
      # @return [Array<Resource::Base>]
      #   a list of resources in the collection
      #
      def collection(prefix = {})
        connection.get(expanded_collection_path(prefix))
      end

      #
      # The path to an individual resource.
      #
      # @param [Hash] prefix
      #   the list of prefix options
      #
      # @return [String]
      #   the path to the resource
      #
      def resource_path(id, prefix = {})
        [expanded_collection_path(prefix), id].join('/')
      end

      #
      # Expand the collection path, "interpolating" any parameters. This syntax
      # is heavily borrowed from Rails and it will make more sense by looking
      # at an example.
      #
      # @example
      #   /bacon, {} #=> "foo"
      #   /bacon/:type, { type: 'crispy' } #=> "bacon/crispy"
      #
      # @raise [Error::MissingURLParameter]
      #   if a required parameter is not given
      #
      # @param [Hash] prefix
      #   the list of prefix options
      #
      # @return [String]
      #   the "interpolated" URL string
      #
      def expanded_collection_path(prefix = {})
        collection_path.gsub(/:\w+/) do |param|
          key = param.delete(':')
          value = prefix[key] || prefix[key.to_sym]

          if value.nil?
            raise Error::MissingURLParameter.new(param: key)
          end

          URI.escape(value)
        end.sub(/^\//, '') # Remove leading slash
      end

      #
      # The current connection object.
      #
      # @return [ChefAPI::Connection]
      #
      def connection
        Thread.current['chefapi.connection'] || ChefAPI.connection
      end
    end

    #
    # The list of associations.
    #
    # @return [Hash]
    #
    attr_reader :associations

    #
    # Initialize a new resource with the given attributes. These attributes
    # are merged with the default values from the schema. Any attributes
    # that aren't defined in the schema are silently ignored for security
    # purposes.
    #
    # @example create a resource using attributes
    #   Bacon.new(foo: 'bar', zip: 'zap') #=> #<ChefAPI::Resource::Bacon>
    #
    # @example using a block
    #   Bacon.new do |bacon|
    #     bacon.foo = 'bar'
    #     bacon.zip = 'zap'
    #   end
    #
    # @param [Hash] attributes
    #   the list of initial attributes to set on the model
    # @param [Hash] prefix
    #   the list of prefix options (for nested resources)
    #
    def initialize(attributes = {}, prefix = {})
      @schema = self.class.schema.dup
      @schema.load_flavor(self.class.connection.flavor)

      @associations = {}
      @_prefix      = prefix

      # Define a getter and setter method for each attribute in the schema
      _attributes.each do |key, value|
        define_singleton_method(key) { _attributes[key] }
        define_singleton_method("#{key}=") { |value| update_attribute(key, value) }
      end

      attributes.each do |key, value|
        unless ignore_attribute?(key)
          update_attribute(key, value)
        end
      end

      yield self if block_given?
    end

    #
    # The primary key for the resource.
    #
    # @return [Symbol]
    #   the primary key for this resource
    #
    def primary_key
      @schema.primary_key
    end

    #
    # The unique id for this resource.
    #
    # @return [Object]
    #
    def id
      _attributes[primary_key]
    end

    #
    # @todo doc
    #
    def _prefix
      @_prefix
    end

    #
    # The list of attributes on this resource.
    #
    # @return [Hash<Symbol, Object>]
    #
    def _attributes
      @_attributes ||= {}.merge(@schema.attributes)
    end

    #
    # Determine if this resource has the given attribute.
    #
    # @param [Symbol, String] key
    #   the attribute key to find
    #
    # @return [Boolean]
    #   true if the attribute exists, false otherwise
    #
    def attribute?(key)
      _attributes.has_key?(key.to_sym)
    end

    #
    # Determine if this current resource is protected. Resources may be
    # protected by name or by a Proc. A protected resource is one that should
    # not be modified (i.e. created/updated/deleted) by the user. An example of
    # a protected resource is the pivotal key or the chef-webui client.
    #
    # @return [Boolean]
    #
    def protected?
      @protected ||= self.class.protected_resources.any? do |thing|
                       if thing.is_a?(Proc)
                         thing.call(self)
                       else
                         id == thing
                       end
                     end
    end

    #
    # Reload (or reset) this object using the values currently stored on the
    # remote server. This method will also clear any cached collection proxies
    # so they will be reloaded the next time they are requested. If the remote
    # record does not exist, no attributes are modified.
    #
    # @note This will remove any custom values you have set on the resource!
    #
    # @return [self]
    #   the instance of the reloaded record
    #
    def reload!
      associations.clear

      remote = self.class.fetch(id, _prefix)
      return self if remote.nil?

      remote._attributes.each do |key, value|
        update_attribute(key, value)
      end

      self
    end

    #
    # Commit the resource and any changes to the remote Chef Server. Any errors
    # will raise an exception in the main thread and the resource will not be
    # committed back to the Chef Server.
    #
    # Any response errors (such as server-side responses) that ChefAPI failed
    # to account for in validations will also raise an exception.
    #
    # @return [Boolean]
    #   true if the resource was saved
    #
    def save!
      validate!

      response = if new_resource?
                   self.class.post(to_json, _prefix)
                 else
                   self.class.put(id, to_json, _prefix)
                 end

      # Update our local copy with any partial information that was returned
      # from the server, ignoring an "bad" attributes that aren't defined in
      # our schema.
      response.each do |key, value|
        update_attribute(key, value) if attribute?(key)
      end

      true
    end

    #
    # Commit the resource and any changes to the remote Chef Server. Any errors
    # are gracefully handled and added to the resource's error collection for
    # handling.
    #
    # @return [Boolean]
    #   true if the save was successfuly, false otherwise
    #
    def save
      save!
    rescue
      false
    end

    #
    # Remove the resource from the Chef Server.
    #
    # @return [self]
    #   the current instance of this object
    #
    def destroy
      self.class.delete(id, _prefix)
      self
    end

    #
    # Update a subset of attributes on the current resource. This is a handy
    # way to update multiple attributes at once.
    #
    # @param [Hash] attributes
    #   the list of attributes to update
    #
    # @return [self]
    #
    def update(attributes = {})
      attributes.each do |key, value|
        update_attribute(key, value)
      end

      self
    end

    #
    # Update a single attribute in the attributes hash.
    #
    # @raise
    #
    def update_attribute(key, value)
      unless attribute?(key.to_sym)
        raise Error::UnknownAttribute.new(attribute: key)
      end

      _attributes[key.to_sym] = value
    end

    #
    # The list of validators for this resource. This is primarily set and
    # managed by the underlying schema clean room.
    #
    # @return [Array<~Validator::Base>]
    #   the list of validators for this resource
    #
    def validators
      @validators ||= @schema.validators
    end

    #
    # Run all of this resource's validations, raising an exception if any
    # validations fail.
    #
    # @raise [Error::InvalidResource]
    #   if any of the validations fail
    #
    # @return [Boolean]
    #   true if the validation was successful - this method will never return
    #   anything other than true because an exception is raised if validations
    #   fail
    #
    def validate!
      unless valid?
        sentence = errors.full_messages.join(', ')
        raise Error::InvalidResource.new(errors: sentence)
      end

      true
    end

    #
    # Determine if the current resource is valid. This relies on the
    # validations defined in the schema at initialization.
    #
    # @return [Boolean]
    #   true if the resource is valid, false otherwise
    #
    def valid?
      errors.clear

      validators.each do |validator|
        validator.validate(self)
      end

      errors.empty?
    end

    #
    # Check if this resource exists on the remote Chef Server. This is useful
    # when determining if a resource should be saved or updated, since a
    # resource must exist before it can be saved.
    #
    # @example when the resource does not exist on the remote Chef Server
    #   bacon = Bacon.new
    #   bacon.new_resource? #=> true
    #
    # @example when the resource exists on the remote Chef Server
    #   bacon = Bacon.first
    #   bacon.new_resource? #=> false
    #
    # @return [Boolean]
    #   true if the resource exists on the remote Chef Server, false otherwise
    #
    def new_resource?
      !self.class.exists?(id, _prefix)
    end

    #
    # Check if the local resource is in sync with the remote Chef Server. When
    # a remote resource is updated, ChefAPI has no way of knowing it's cached
    # resources are dirty unless additional requests are made against the
    # remote Chef Server and diffs are compared.
    #
    # @example when the resource is out of sync with the remote Chef Server
    #   bacon = Bacon.first
    #   bacon.description = "I'm different, yeah, I'm different!"
    #   bacon.dirty? #=> true
    #
    # @example when the resource is in sync with the remote Chef Server
    #   bacon = Bacon.first
    #   bacon.dirty? #=> false
    #
    # @return [Boolean]
    #   true if the local resource has differing attributes from the same
    #   resource on the remote Chef Server, false otherwise
    #
    def dirty?
      new_resource? || !diff.empty?
    end

    #
    # Calculate a differential of the attributes on the local resource with
    # it's remote Chef Server counterpart.
    #
    # @example when the local resource is in sync with the remote resource
    #   bacon = Bacon.first
    #   bacon.diff #=> {}
    #
    # @example when the local resource differs from the remote resource
    #   bacon = Bacon.first
    #   bacon.description = "My new description"
    #   bacon.diff #=> { :description => { :local => "My new description", :remote => "Old description" } }
    #
    # @note This is a VERY expensive operation - use it sparringly!
    #
    # @return [Hash]
    #
    def diff
      diff = {}

      remote = self.class.fetch(id, _prefix) || self.class.new({}, _prefix)
      remote._attributes.each do |key, value|
        unless _attributes[key] == value
          diff[key] = { local: _attributes[key], remote: value }
        end
      end

      diff
    end

    #
    # The URL for this resource on the Chef Server.
    #
    # @example Get the resource path for a resource
    #   bacon = Bacon.first
    #   bacon.resource_path #=> /bacons/crispy
    #
    # @return [String]
    #   the partial URL path segment
    #
    def resource_path
      self.class.resource_path(id, _prefix)
    end

    #
    # Determine if a given attribute should be ignored. Ignored attributes
    # are defined at the schema level and are frozen.
    #
    # @param [Symbol] key
    #   the attribute to check ignorance
    #
    # @return [Boolean]
    #
    def ignore_attribute?(key)
      @schema.ignored_attributes.has_key?(key.to_sym)
    end

    #
    # The collection of errors on the resource.
    #
    # @return [ErrorCollection]
    #
    def errors
      @errors ||= ErrorCollection.new
    end

    #
    # The hash representation of this resource. All attributes are serialized
    # and any values that respond to +to_hash+ are also serialized.
    #
    # @return [Hash]
    #
    def to_hash
      {}.tap do |hash|
        _attributes.each do |key, value|
          hash[key] = value.respond_to?(:to_hash) ? value.to_hash : value
        end
      end
    end

    #
    # The JSON serialization of this resource.
    #
    # @return [String]
    #
    def to_json(*)
      JSON.fast_generate(to_hash)
    end

    #
    # Custom to_s method for easier readability.
    #
    # @return [String]
    #
    def to_s
      "#<#{self.class.classname} #{primary_key}: #{id.inspect}>"
    end

    #
    # Custom inspect method for easier readability.
    #
    # @return [String]
    #
    def inspect
      attrs = (_prefix).merge(_attributes).map do |key, value|
        if value.is_a?(String)
          "#{key}: #{Util.truncate(value, length: 50).inspect}"
        else
          "#{key}: #{value.inspect}"
        end
      end

      "#<#{self.class.classname} #{attrs.join(', ')}>"
    end
  end
end
