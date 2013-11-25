module ChefAPI
  class Validator::Base
    #
    # @return [Symbol]
    #   the attribute to apply this validation on
    #
    attr_reader :attribute

    #
    # @return [Hash]
    #   the hash of additional arguments passed in
    #
    attr_reader :options

    #
    # Create anew validator.
    #
    # @param [Symbol] attribute
    #   the attribute to apply this validation on
    # @param [Hash] options
    #   the list of options passed in
    #
    def initialize(attribute, options = {})
      @attribute = attribute
      @options   = options.is_a?(Hash) ? options : {}
    end

    #
    # Just in case someone forgets to define a key, this will return the
    # class's underscored name without "validator" as a symbol.
    #
    # @example
    #   FooValidator.new.key #=> :foo
    #
    # @return [Symbol]
    #
    def key
      name = self.class.name.split('::').last
      Util.underscore(name).to_sym
    end

    #
    # Execute the validations. This is an abstract class and must be
    # overridden in custom validators.
    #
    # @param [Resource::Base::Base] resource
    #   the parent resource to validate against
    #
    def validate(resource)
      raise Error::AbstractMethod.new(method: 'Validators::Base#validate')
    end

    #
    # The string representation of this validation.
    #
    # @return [String]
    #
    def to_s
      "#<#{classname}>"
    end

    #
    # The string representation of this validation.
    #
    # @return [String]
    #
    def inspect
      "#<#{classname} :#{attribute}>"
    end

    private

    #
    # The class name for this validator.
    #
    # @return [String]
    #
    def classname
      @classname ||= self.class.name.split('::')[1..-1].join('::')
    end
  end
end
