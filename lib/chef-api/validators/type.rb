module ChefAPI
  class Validator::Type < Validator::Base
    attr_reader :types

    #
    # Overload the super method to capture the type attribute in the options
    # hash.
    #
    def initialize(attribute, type)
      super
      @types = Array(type)
    end

    def validate(resource)
      value = resource._attributes[attribute]

      if value && !types.any? { |type| value.is_a?(type) }
        short_name = type.to_s.split('::').last
        resource.errors.add(attribute, "must be a kind of #{short_name}")
      end
    end
  end
end
