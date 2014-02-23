module ChefAPI
  class Resource::DataBag < Resource::Base
    collection_path '/data'

    schema do
      attribute :name, type: String, primary: true, required: true
    end

    class << self
      #
      # Load the data bag from a collection of JSON files on disk. Just like
      # +knife+, the basename of the folder is assumed to be the name of the
      # data bag and all containing items a proper JSON data bag.
      #
      # This will load **all** items in the data bag, returning an array of
      # those items. To load an individual data bag item, see
      # {DataBagItem.from_file}.
      #
      # **This method does NOT return an instance of a {DataBag}!**
      #
      # @param [String] path
      #   the path to the data bag **folder** on disk
      # @param [String] name
      #   the name of the data bag
      #
      # @return [Array<DataBagItem>]
      #
      def from_file(path, name = File.basename(path))
        path  = File.expand_path(path)

        raise Error::FileNotFound.new(path: path)  unless File.exists?(path)
        raise Error::NotADirectory.new(path: path) unless File.directory?(path)

        raise ArgumentError unless File.directory?(path)

        bag = new(name: name)

        Util.fast_collect(Dir["#{path}/*.json"]) do |item|
          DataBagItem.from_file(item, bag)
        end
      end

      #
      #
      #
      def fetch(id, prefix = {})
        return nil if id.nil?

        path     = resource_path(id, prefix)
        response = connection.get(path)
        new(name: id)
      rescue Error::HTTPNotFound
        nil
      end

      #
      #
      #
      def each(&block)
        collection.each do |name, path|
          result = new(name: name)
          block.call(result) if block
        end
      end
    end

    #
    # This is the same as +has_many :items+, but creates a special collection
    # for data bag items, which is mutable and handles some special edge cases
    # that only data bags encounter.
    #
    # @see Base.has_many
    #
    def items
      associations[:items] ||= Resource::DataBagItemCollectionProxy.new(self)
    end
  end
end

module ChefAPI
  #
  # The mutable collection is a special kind of collection proxy that permits
  # Rails-like attribtue creation, like:
  #
  #   DataBag.first.items.create(id: 'me', thing: 'bar', zip: 'zap')
  #
  class Resource::DataBagItemCollectionProxy < Resource::CollectionProxy
    def initialize(bag)
      # Delegate to the superclass
      super(bag, Resource::DataBagItem, nil, bag: bag.name)
    end

    # @see klass.new
    def new(data = {})
      klass.new(data, prefix, parent)
    end

    # @see klass.destroy
    def destroy(id)
      klass.destroy(id, prefix)
    ensure
      reload!
    end

    # @see klass.destroy_all
    def destroy_all
      klass.destroy_all(prefix)
    ensure
      reload!
    end

    # @see klass.build
    def build(data = {})
      klass.build(data, prefix)
    end

    # @see klass.create
    def create(data = {})
      klass.create(data, prefix)
    ensure
      reload!
    end

    # @see klass.create!
    def create!(data = {})
      klass.create!(data, prefix)
    ensure
      reload!
    end

    # @see klass.update
    def update(id, data = {})
      klass.update(id, data, prefix)
    end
  end
end
