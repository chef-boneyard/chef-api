# ChefAPI Client

[![Gem Version](http://img.shields.io/gem/v/chef-api.svg)][gem] [![Build Status](http://img.shields.io/travis/sethvargo/chef-api.svg)][travis]

**ChefAPI is currently in rapid development!** You should not consider this API stable until the official 1.0.0 release.

ChefAPI is a dependency-minimal Ruby client for interacting with a Chef Server. It adopts many patterns and principles from Rails

## Quick start

Install via Rubygems:

```
$ gem install chef-api
```

or add it to your Gemfile if you are using Bundler:

```ruby
gem 'chef-api', '~> 0.1'
```

In your library or project, you will likely want to include the `ChefAPI::Resource` namespace:

```ruby
include ChefAPI::Resource
```

This will give you "Rails-like" access to the top-level Chef resources like:

```ruby
Client.all
Node.all
```

If you choose not to include the module, you will need to specify the full module path to access resources:

```ruby
ChefAPI::Resource::Client.all
ChefAPI::Resource::Node.all
```

### Create a connection

Before you can make a request, you must give the ChefAPI your connection information and credentials.

```ruby
ChefAPI.configure do |config|
  # The endpoint for the Chef Server. This can be an Open Source Chef Server,
  # Hosted Chef Server, or Enterprise Chef Server.
  config.endpoint = 'https://api.opscode.com/organizations/meats'

  # ChefAPI will try to determine if you are running on an Enterprise Chef
  # Server or Open Source Chef depending on the URL you provide for the
  # +endpoint+ attribute. However, it may be incorrect. If is seems like the
  # generated schema does not match the response from the server, it is
  # possible this value was calculated incorrectly. Thus, you should set it
  # manually. Possible values are +:enterprise+ and +:open_source+.
  config.flavor = :enterprise

  # The client and key must also be specified (unless you are running Chef Zero
  # in no-authentication mode). The +key+ attribute may be the raw private key,
  # the path to the private key on disk, or an +OpenSSLL::PKey+ object.
  config.client = 'bacon'
  config.key    = '~/.chef/bacon.pem'

  # If you are running your own Chef Server with a custom SSL certificate, you
  # will need to specify the path to a pem file with your custom certificates
  # and ChefAPI will wire everything up correctly. (NOTE: it must be a valid
  # PEM file).
  config.ssl_pem_file = '/path/to/my.pem'

  # If you would like to be vulnerable to MITM attacks, you can also turn off
  # SSL verification. Despite what Internet blog posts may suggest, you should
  # exhaust other methods before disabling SSL verification. ChefAPI will emit
  # a warning message for every request issued with SSL verification disabled.
  config.ssl_verify = false

  # If you are behind a proxy, Chef API can run requests through the proxy as
  # well. Just set the following configuration parameters as needed.
  config.proxy_username = 'user'
  config.proxy_password = 'password'
  config.proxy_address  = 'my.proxy.server' # or 10.0.0.50
  config.proxy_port     = '8080'

  # If you want to make queries that return a very large result chef, you might
  # need to adjust the timeout limits for the network request. (NOTE: time is
  # given in seconds).
  config.read_timeout = 120
end
```

All of these configuration options are available via the top-level `ChefAPI` object.

```ruby
ChefAPI.endpoint = '...'
```

You can also configure everything via environment variables (great solution for Docker-based usage). All the environment variables are of the format `CHEF_API_{key}`, where `key` is the uppercase equivalent of the item in the configuration object.

```bash
# ChefAPI will use these values
export CHEF_API_ENDPOINT=https://api.opscode.com/organizations/meats
export CHEF_API_CLIENT=bacon
export CHEF_API_KEY=~/.chef/bacon.pem
```

In addition, you can configure the environment variables in a JSON-formatted config file either placed in ~/.chef-api or placed in a location configured via the environment variable `CHEF_API_CONFIG`. For example:

```json
{
  "CHEF_API_ENDPOINT": "https://api.opscode.com/organizations/meats",
  "CHEF_API_CLIENT": "bacon",
  "CHEF_API_KEY": "~/.chef/bacon.pem"
}
```

If you prefer a more object-oriented approach (or if you want to support multiple simultaneous connections), you can create a raw `ChefAPI::Connection` object. All of the options that are available on the `ChefAPI` object are also available on a raw connection:

```ruby
connection = ChefAPI::Connection.new(
  endpoint: 'https://api.opscode.com/organizations/meats',
  client:   'bacon',
  key:      '~/.chef/bacon.pem'
)

connection.clients.fetch('chef-webui')
connection.environments.delete('production')
```

If you do not want to manage a `ChefAPI::Connection` object, or if you just prefer an alternative syntax, you can use the block-form:

```ruby
ChefAPI::Connection.new do |connection|
  connection.endpoint = 'https://api.opscode.com/organizations/meats'
  connection.client   = 'bacon'
  connection.key      = '~/.chef/bacon.pem'

  # The connection object is now setup, so you can use it directly:
  connection.clients.fetch('chef-webui')
  connection.environments.delete('production')
end
```

### Making Requests

The ChefAPI gem attempts to wrap the Chef Server API in an object-oriented and Rubyesque way. All of the methods and API calls are heavily documented inline using YARD. For a full list of every possible option, please see the inline documentation.

Most resources can be listed, retrieved, created, updated, and destroyed. In programming, this is commonly referred to as "CRUD".

#### Create

There are multiple ways to create a new Chef resource on the remote Chef Server. You can use the native `create` method. It accepts a list of parameters as a hash:

```ruby
Client.create(name: 'new-client') #=> #<Resource::Client name: "new-client", admin: false, ...>
```

Or you can create an instance of the object, setting parameters as you go.

```ruby
client = Client.new
client.name = 'new-client'
client.save #=> #<Resource::Client name: "new-client", admin: false, ...>
```

You can also mix-and-match the hash and object initialization:

```ruby
client = Client.new(name: 'new-client')
client.validator = true
client.admin = true
client.save #=> #<Resource::Client name: "new-client", admin: false, ...>
```

#### Read

Most resources have the following "read" functions:

- `.list`, `.all`, and `.each` for listing Chef resources
- `.fetch` for getting a single Chef resource with the given identifier

##### Listing

You can get a list of all the identifiers for a given type of resource using the `.list` method. This is especially useful when you only want to list items by their identifier, since it only issues a single API request. For example, to get the names of all of the Client resources:

```ruby
Client.list #=> ["chef-webui", "validator"]
```

You can also get the full collection of Chef resources using the `.all` method:

```ruby
Client.all #=> [#<Resource::Client name: "chef-webui", admin: false ...>,
                #<Resource::Client name: "validator", admin: false ...>]
```

However, this is incredibly inefficient. Because of the way the Chef Server serves requests, this will make N+1 queries to the Chef Server. Unless you absolutely need every resource in the collection, you are much better using the lazy enumerable:

```ruby
Client.each do |client|
  puts client.name
end
```

Because the resources include Ruby's custom Enumerable, you can treat the top-level resources as if they were native Ruby enumerable objects. Here are just a few examples:

```ruby
Client.first #=> #<Resource::Client name: "chef-webui" ...>
Client.first(3) #=> [#<Resource::Client name: "chef-webui" ...>, ...]
Client.map(&:public_key) #=> ["-----BEGIN PUBLIC KEY-----\nMIGfMA...", "-----BEGIN PUBLIC KEY-----\nMIIBI..."]
```

##### Fetching

You can also fetch a single resource from the Chef Server using the given identifier. Each Chef resource has a unique identifier; internally this is called the "primary key". For most resources, this attribute is "name". You can fetch a resource by it's primary key using the `.fetch` method:

```ruby
Client.fetch('chef-webui') #=> #<Resource::Client name: "chef-webui" ...>
```

If a resource with the given identifier does not exist, it will return `nil`:

```ruby
Client.fetch('not-a-real-client') #=> nil
```

#### Update

You can update a resource using it's unique identifier and a list of hash attributes:

```ruby
Client.update('chef-webui', admin: true)
```

Or you can get an instance of the object and update the attributes manually:

```ruby
client = Client.fetch('chef-webui')
client.admin = true
client.save
```

#### Delete

You can destroy a resource using it's unique identifier:

```ruby
Client.destroy('chef-webui') #=> true
```

Or you can get an instance of the object and delete it manually:

```ruby
client = Client.fetch('chef-webui')
client.destroy #=> true
```

### Validations

Each resource includes its own validations. If these validations fail, they exhibit custom errors messages that are added to the resource. For example, Chef clients **must** have a name attribute. This is validated on the client side:

```ruby
client = Client.new
client.save #=> false
```

Notice that the `client.save` call returned `false`? This is an indication that the resource did not commit back to the server because of a failed validation. You can get the error(s) that prevented the object from saving using the `.errors` method on an instance:

```ruby
client.errors #=> { :name => ["must be present"] }
```

Just like Rails, you can also get the human-readable list of these errors by calling `#full_messages` on the errors hash. This is useful if you are using ChefAPI as a library and want to give developers a semantic error:

```ruby
client.errors.full_messages #=> ["`name' must be present"]
```

You can also force ChefAPI to raise an exception if the validations fail, using the "bang" version of save - `save!`:

```ruby
client.save! #=> InvalidResource: There were errors saving your resource: `name' must be present
```

### Objects on Disk

ChefAPI also has the ability to read and manipulate objects on disk. This varies from resource-to-resource, but the `.from_file` method accepts a path to a resource on disk and loads as much information about the object on disk as it can. The attributes are then merged with the remote resource, if one exists. For example, you can read a Client resource from disk:

```ruby
client = Client.from_file('~/.chef/bacon.pem') #=> #<Resource::Client name: "bacon", admin: false, public_key: nil, private_key: "..." ...>
```

## Searching

ChefAPI employs both search and partial search functionality.

```ruby
# Using regular search
results = Search.query(:node, '*:*', start: 1)
results.total #=> 5_000
results.rows.each do |result|
  puts result
end

# Using partial search
results = PartialSearch.query(:node, { data: ['fqdn'] }, start: 1)
results.total #=> 2
results.rows.each do |result|
  puts result
end
```

## FAQ

**Q: How is this different than [Ridley](https://github.com/RiotGames/ridley)?**<br>
A: Ridley is optimized for highly concurrent connections with support for multiple Chef Servers. ChefAPI is designed for the "average user" who does not need the advanced use cases that Ridley provides. For this reason, the ChefAPI is incredibly opinionated about the features it will include. If you need complex features, take a look at [Ridley](https://github.com/RiotGames/ridley).

## Development

1. Clone the project on GitHub
2. Create a feature branch
3. Submit a Pull Request

Important Notes:

- **All new features must include test coverage.** At a bare minimum, Unit tests are required. It is preferred if you include acceptance tests as well.
- **The tests must be be idempotent.** The HTTP calls made during a test should be able to be run over and over.
- **Tests are order independent.** The default RSpec configuration randomizes the test order, so this should not be a problem.

## License & Authors

- Author: Seth Vargo [sethvargo@gmail.com](mailto:sethvargo@gmail.com)

```text
Copyright 2013-2014 Seth Vargo

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

[gem]: https://rubygems.org/gems/chef-api
[travis]: http://travis-ci.org/sethvargo/chef-api
