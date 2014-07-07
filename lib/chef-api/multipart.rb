require 'cgi'
require 'mime/types'

module ChefAPI
  module Multipart
    BOUNDARY = '------ChefAPIMultipartBoundary'.freeze

    class Body
      def initialize(params = {})
        params.each do |key, value|
          if value.respond_to?(:read)
            parts << FilePart.new(key, value)
          else
            parts << ParamPart.new(key, value)
          end
        end

        parts << EndingPart.new
      end

      def stream
        MultiIO.new(*parts.map(&:io))
      end

      def content_type
        "multipart/form-data; boundary=#{BOUNDARY}"
      end

      def content_length
        parts.map(&:size).inject(:+)
      end

      private

      def parts
        @parts ||= []
      end
    end

    class MultiIO
      attr_reader :ios

      def initialize(*ios)
        @ios = ios
        @index = 0
      end

      # Read from IOs in order until `length` bytes have been received.
      def read(length = nil, outbuf = nil)
        got_result = false
        outbuf = outbuf ? outbuf.replace('') : ''

        while io = current_io
          if result = io.read(length)
            got_result ||= !result.nil?
            result.force_encoding('BINARY') if result.respond_to?(:force_encoding)
            outbuf << result
            length -= result.length if length
            break if length == 0
          end
          advance_io
        end

        (!got_result && length) ? nil : outbuf
      end

      def rewind
        @ios.each { |io| io.rewind }
        @index = 0
      end

      private

      def current_io
        @ios[@index]
      end

      def advance_io
        @index += 1
      end
    end

    #
    # A generic key => value part.
    #
    class ParamPart
      def initialize(name, value)
        @part = build(name, value)
      end

      def io
        @io ||= StringIO.new(@part)
      end

      def size
        @part.bytesize
      end

      private

      def build(name, value)
        part =  %|--#{BOUNDARY}\r\n|
        part << %|Content-Disposition: form-data; name="#{CGI.escape(name)}"\r\n\r\n|
        part << %|#{value}\r\n|
        part
      end
    end

    #
    # A File part
    #
    class FilePart
      def initialize(name, file)
        @file = file
        @head = build(name, file)
        @foot = "\r\n"
      end

      def io
        @io ||= MultiIO.new(
          StringIO.new(@head),
          @file,
          StringIO.new(@foot)
        )
      end

      def size
        @head.bytesize + @file.size + @foot.bytesize
      end

      private

      def build(name, file)
        filename  = File.basename(file.path)
        mime_type = MIME::Types.type_for(filename)[0] || MIME::Types['application/octet-stream'][0]

        part =  %|--#{BOUNDARY}\r\n|
        part << %|Content-Disposition: form-data; name="#{CGI.escape(name)}"; filename="#{filename}"\r\n|
        part << %|Content-Length: #{file.size}\r\n|
        part << %|Content-Type: #{mime_type.simplified}\r\n|
        part << %|Content-Transfer-Encoding: binary\r\n|
        part << %|\r\n|
        part
      end
    end

    #
    # The end of the entire request
    #
    class EndingPart
      def initialize
        @part = "--#{BOUNDARY}--\r\n\r\n"
      end

      def io
        @io ||= StringIO.new(@part)
      end

      def size
        @part.bytesize
      end
    end
  end
end
