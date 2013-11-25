module ChefAPI
  class SchemaError < ChefAPIError; end

  class MissingRequiredAttribute < SchemaError
    def initialize(key)
      super "Attribute `#{key}` is missing!"
    end
  end

  class InvalidAttributeType < SchemaError
    def initialize(key, type, value)
      super "Attribute `#{key}` must be #{type}, but was #{value.class}!"
    end
  end

  #
  # A wrapper class that describes a remote schema (such as the Chef Server
  # API layer), with validation and other magic spinkled on top.
  #
  class Schema
    attr_reader :options

    def initialize(options = {}, &block)
      @options = options.dup
      instance_eval(&block) if block
    end

    #
    # Load the given attributes into the schema, mapping them to their
    # appropiate values. Any attributes that are not explicitly defined in the
    # schema are silently ignored. This is because the response from the
    # server cannot be trusted!
    #
    # @example
    #   schema.load(foo: 'bar', zip: 'zap') #=> #<ChefAPI::Schema @attributes={...}>
    #
    # @param [Hash] attributes
    #   the list of attributes to set
    #
    # @return [Schema]
    #   the reference to the receiving object, for chaining purposes
    #
    def load(attributes = {})
      attributes.each do |key, value|
        if schema.has_key?(key.to_sym)
          schema[key.to_sym][:value] = value
        end
      end

      self
    end

    #
    # The primary key for the schema. If a primary key was not specified, the
    # first +attribute+ entry is used.
    #
    # @return [Symbol]
    #   the primary key for this schema
    #
    def primary_key
      @primary_key ||= schema.first[0]
    end

    #
    # DSL method for defining an attribute.
    #
    # @param [Symbol] key
    #   the key to use
    # @param [Hash] options
    #   a list of options to create the attribute with
    #
    # @return [Schema]
    #   the current instnace
    #
    def attribute(key, options = {})
      if options[:primary]
        @primary_key = key.to_sym
      end

      schema[key.to_sym] = options

      instance_eval <<-EOH, __FILE__, __LINE__ + 1
        def #{key}
          compiled_schema[:#{key}]
        end

        def #{key}=(value)
          schema[:#{key}][:value] = value
        end
      EOH

      self
    end

    #
    # Iterate through all the options in the schema, validating the correct
    # validations are present.
    #
    # @raise [MissingRequiredAttribute]
    #   if the schema specifies an attribute must be required, but it is not
    #   present
    # @raise [InvalidAttributeType]
    #   if the schema specifies an attribute type, but the given value is
    #   not that type
    #
    # @return [Boolean]
    #   true if the validation was successful
    #
    def validate!
      schema.each do |key, options|
        if options.has_key?(:value)
          if options[:type] && !options[:value].is_a?(options[:type])
            raise InvalidAttributeType.new(key, options[:type], options[:value])
          end
        else
          if options[:required]
            raise MissingRequiredAttribute.new(key)
          end
        end
      end

      true
    end

    #
    # Determine if the current schema is valid.
    #
    # @return [Boolean]
    #   true if the schema is valid, false otherwise
    #
    def valid?
      validate!
      true
    rescue SchemaError
      false
    end

    private

      #
      # The underlying hash that represents the schema. Don't touch this
      # unless you know what you're doing...
      #
      # @return [Hash]
      #
      def schema
        @schema ||= {}
      end

      #
      # The compiled schema, with default values and set values combined into
      # a single hash. The method is intentionally uncached and calculated on
      # each run.
      #
      # @retrun [Hash]
      #
      def compiled_schema
        Hash[*schema.map { |k, v| [k, v[:value] || v[:default]] }.flatten(1)]
      end

  end
end
