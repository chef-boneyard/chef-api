require 'erb'

module ChefAPI
  module Error
    class ErrorBinding
      def initialize(options = {})
        options.each do |key, value|
          instance_variable_set(:"@#{key}", value)
        end
      end

      def get_binding
        binding
      end
    end

    class ChefAPIError < StandardError
      def initialize(options = {})
        @options  = options
        @filename = options.delete(:_template)

        super()
      end

      def message
        erb = ERB.new(File.read(template))
        erb.result(ErrorBinding.new(@options).get_binding)
      end
      alias_method :to_s, :message

      private

      def template
        class_name = self.class.to_s.split('::').last
        filename   = @filename || Util.underscore(class_name)
        ChefAPI.root.join('templates', 'errors', "#{filename}.erb")
      end
    end

    class AbstractMethod < ChefAPIError; end
    class CannotRegenerateKey < ChefAPIError; end
    class FileNotFound < ChefAPIError; end

    class HTTPError < ChefAPIError; end
    class HTTPBadRequest < HTTPError; end
    class HTTPForbiddenRequest < HTTPError; end
    class HTTPGatewayTimeout < HTTPError; end
    class HTTPNotAcceptable < HTTPError; end
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
