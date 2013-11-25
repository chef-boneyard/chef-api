module ChefAPI
  #
  # Create a proxy object, which delegates all methods to the class given in
  # the initializer. This is used by the client object to filter the first
  # parameter of any singleton methods to pass in the given client as the first
  # argument. It's dirty, but it allows developers to write pretty code, which
  # is more what I care about.
  #
  # @example Without a proxy object
  #   client = ChefAPI::Client.new('...')
  #   repo = ChefAPI::Resource::Repository.new(client, name: '...')
  #
  # @example With a proxy object
  #   client = ChefAPI::Client.new('...')
  #   repo = client.repositories.new(name: '...')
  #
  class Proxy < BasicObject
    #
    # This is quite possibly the worst thing I've ever done in my life.
    # Dynamically remove all methods from this class, just we we can delegate
    # *everything* to the instance class.
    #
    # It is presumed there is no hope...
    #
    instance_methods.each do |name|
      unless name =~ /__|object_id|instance_eval/
        undef_method name
      end
    end

    #
    # Create a new proxy object.
    #
    # @param [ChefAPI::Client] client
    #   the client object to use for the proxy
    # @param [Class] klass
    #   the class to proxy to
    #
    def initialize(client, klass)
      @client = client
      @klass  = klass

      klass.singleton_methods.each do |name|
        instance_eval <<-EOH, __FILE__, __LINE__ + 1
          def #{name}(*args)
            if args.last.is_a?(::Hash)
              args.last[:client] = @client
            else
              args << { client: @client }
            end

            @klass.send(:#{name}, *args)
          end
        EOH
      end
    end

    # @private
    def method_missing(m, *args, &block)
      if @klass.respond_to?(m)
        @klass.send(m, *args, &block)
      else
        super
      end
    end

    # @private
    def respond_to_missing?(m, include_private = false)
      @klass.respond_to?(m) || super
    end
  end
end
