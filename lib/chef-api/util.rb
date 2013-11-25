module ChefAPI
  module Util
    extend self

    #
    # Covert the given CaMelCaSeD string to under_score. Graciously borrowed
    # from http://stackoverflow.com/questions/1509915.
    #
    # @param [String] string
    #   the string to use for transformation
    #
    # @return [String]
    #
    def underscore(string)
      string
        .to_s
        .gsub(/::/, '/')
        .gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
        .gsub(/([a-z\d])([A-Z])/,'\1_\2')
        .tr('-', '_')
        .downcase
    end

    #
    # Convert an underscored string to it's camelcase equivalent constant.
    #
    # @param [String] string
    #   the string to convert
    #
    # @return [String]
    #
    def camelize(string)
      string
        .to_s
        .split('_')
        .map { |e| e.capitalize }
        .join
    end

    #
    # Truncate the given string to a certain number of characters.
    #
    # @param [String] string
    #   the string to truncate
    # @param [Hash] options
    #   the list of options (such as +length+)
    #
    def truncate(string, options = {})
      length = options[:length] || 30

      if string.length > length
        string[0..length-3] + '...'
      else
        string
      end
    end

    #
    # "Safely" read the contents of a file on disk, catching any permission
    # errors or not found errors and raising a nicer exception.
    #
    # @example Reading a file that does not exist
    #   safe_read('/non-existent/file') #=> Error::FileNotFound
    #
    # @example Reading a file with improper permissions
    #   safe_read('/bad-permissions') #=> Error::InsufficientFilePermissions
    #
    # @example Reading a regular file
    #   safe_read('my-file.txt') #=> ["my-file", "..."]
    #
    # @param [String] path
    #   the path to the file on disk
    #
    # @return [Array<String>]
    #   A array where the first value is the basename of the file and the
    #   second value is the literal contents from +File.read+.
    #
    def safe_read(path)
      path     = File.expand_path(path)
      name     = File.basename(path, '.*')
      contents = File.read(path)

      [name, contents]
    rescue Errno::EACCES
      raise Error::InsufficientFilePermissions.new(path: path)
    rescue Errno::ENOENT
      raise Error::FileNotFound.new(path: path)
    end

    #
    # Quickly iterate over a collection using native Ruby threads, preserving
    # the original order of elements and being all thread-safe and stuff.
    #
    # @example Parse a collection of JSON files
    #
    #   fast_collect(Dir['**/*.json']) do |item|
    #     JSON.parse(File.read(item))
    #   end
    #
    # @param [#each] collection
    #   the collection to iterate
    # @param [Proc] block
    #   the block to evaluate (typically an expensive operation)
    #
    # @return [Array]
    #   the result of the iteration
    #
    def fast_collect(collection, &block)
      collection.map do |item|
        Thread.new do
          Thread.current[:result] = block.call(item)
        end
      end.collect do |thread|
        thread.join
        thread[:result]
      end
    end
  end
end
