module ChefAPI
  #
  # A wrapper class that describes a remote schema (such as the Chef Server
  # API layer), with validation and other magic spinkled on top.
  #
  class Schema

    #
    # The full list of attributes defined on this schema.
    #
    # @return [Hash]
    #
    attr_reader :attributes

    attr_reader :ignored_attributes

    #
    # The list of defined validators for this schema.
    #
    # @return [Array]
    #
    attr_reader :validators

    #
    # Create a new schema and evaulte the block contents in a clean room.
    #
    def initialize(&block)
      @attributes = {}
      @ignored_attributes = {}
      @flavor_attributes = {}
      @validators = []

      unlock { instance_eval(&block) } if block
    end

    #
    # The defined primary key for this schema. If no primary key is given, it
    # is assumed to be the first item in the list.
    #
    # @return [Symbol]
    #
    def primary_key
      @primary_key ||= @attributes.first[0]
    end

    #
    #
    #
    def flavor(id, &block)
      @flavor_attributes[id] = block
    end

    #
    #
    #
    def load_flavor(id)
      if block = @flavor_attributes[id]
        unlock { instance_eval(&block) }
      end
    end

    #
    # DSL method for defining an attribute.
    #
    # @param [Symbol] key
    #   the key to use
    # @param [Hash] options
    #   a list of options to create the attribute with
    #
    # @return [Symbol]
    #   the attribute
    #
    def attribute(key, options = {})
      if primary_key = options.delete(:primary)
        @primary_key = key.to_sym
      end

      @attributes[key] = options.delete(:default)

      # All remaining options are assumed to be validations
      options.each do |validation, options|
        if options
          @validators << Validator.find(validation).new(key, options)
        end
      end

      key
    end

    #
    # Ignore an attribute. This is handy if you know there's an attribute that
    # the remote server will return, but you don't want that information
    # exposed to the user (or the data is sensitive).
    #
    # @param [Array<Symbol>] keys
    #   the list of attributes to ignore
    #
    def ignore(*keys)
      keys.each do |key|
        @ignored_attributes[key.to_sym] = true
      end
    end

    private

    def unlock
      @attributes = @attributes.dup
      @ignored_attributes = @ignored_attributes.dup
      @flavor_attributes = @flavor_attributes.dup
      @validators = @validators.dup

      yield

      @attributes.freeze
      @ignored_attributes.freeze
      @flavor_attributes.freeze
      @validators.freeze
    end
  end
end
