module ChefAPI
  #
  # Private internal class for managing the error collection.
  #
  class ErrorCollection < Hash
    #
    # The default proc for the hash needs to be an empty Array.
    #
    # @return [Proc]
    #
    def initialize
      super { |h, k| h[k] = [] }
    end

    #
    # Add a new error to the hash.
    #
    # @param [Symbol] key
    #   the attribute key
    # @param [String] error
    #   the error message to push
    #
    # @return [self]
    #
    def add(key, error)
      self[key].push(error)
      self
    end

    #
    # Output the full messages for each error. This is useful for displaying
    # information about validation to the user when something goes wrong.
    #
    # @return [Array<String>]
    #
    def full_messages
      self.map do |key, errors|
        errors.map do |error|
          "`#{key}' #{error}"
        end
      end.flatten
    end
  end
end
