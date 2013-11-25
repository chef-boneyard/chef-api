module ChefAPI
  module Validator
    autoload :Base,       'chef-api/validators/base'
    autoload :Required,   'chef-api/validators/required'
    autoload :Type,       'chef-api/validators/type'

    #
    # Find a validator by the given key.
    #
    def self.find(key)
      const_get(Util.camelize(key))
    rescue NameError
      raise Error::InvalidValidator.new(key: key)
    end
  end
end
