module ChefAPI
  class Validator::Required < Validator::Base
    def validate(resource)
      value = resource._attributes[attribute]

      if value.to_s.strip.empty?
        resource.errors.add(attribute, 'must be present')
      end
    end
  end
end
