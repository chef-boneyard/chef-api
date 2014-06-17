module ChefAPI
  module Resource
    autoload :Base,            'chef-api/resources/base'
    autoload :Client,          'chef-api/resources/client'
    autoload :CollectionProxy, 'chef-api/resources/collection_proxy'
    autoload :Cookbook,        'chef-api/resources/cookbook'
    autoload :CookbookVersion, 'chef-api/resources/cookbook_version'
    autoload :DataBag,         'chef-api/resources/data_bag'
    autoload :DataBagItem,     'chef-api/resources/data_bag_item'
    autoload :Environment,     'chef-api/resources/environment'
    autoload :Node,            'chef-api/resources/node'
    autoload :Organization,    'chef-api/resources/organization'
    autoload :PartialSearch,   'chef-api/resources/partial_search'
    autoload :Principal,       'chef-api/resources/principal'
    autoload :Role,            'chef-api/resources/role'
    autoload :Search,          'chef-api/resources/search'
    autoload :User,            'chef-api/resources/user'
  end
end
