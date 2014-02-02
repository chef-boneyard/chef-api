module ChefAPI
  module Error
    class ChefAPIError < StandardError
      def initialize(options = {})
        class_name = self.class.to_s.split('::').last
        error_key  = Util.underscore(class_name)

        super I18n.t("chef_api.errors.#{error_key}", options)
      end
    end

    class AbstractMethod < ChefAPIError; end
    class CannotRegenerateKey < ChefAPIError; end
    class FileNotFound < ChefAPIError; end

    class HTTPError < ChefAPIError; end
    class HTTPBadRequest < HTTPError; end
    class HTTPForbiddenRequest < HTTPError; end
    class HTTPNotFound < HTTPError; end
    class HTTPMethodNotAllowed < HTTPError; end
    class HTTPServerUnavailable < HTTPError; end

    class HTTPUnauthorizedRequest < ChefAPIError; end
    class InsufficientFilePermissions < ChefAPIError; end
    class InvalidResource < ChefAPIError; end
    class InvalidValidator < ChefAPIError; end
    class MissingURLParameter < ChefAPIError; end
    class NotADirectory < ChefAPIError; end
    class ResourceAlreadyExists < ChefAPIError; end
    class ResourceNotFound < ChefAPIError; end
    class ResourceNotMutable < ChefAPIError; end
    class UnknownAttribute < ChefAPIError; end
  end
end
