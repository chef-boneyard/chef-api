# ChefAPI Changelog

## v0.8.0 (2018-03-02)

- support `filter_result` in chef queries 
- support a configurable read_timeout

## v0.7.1 (2017-08-06)

- Don't set nil `JSON.create_id` as it's unnecessary in recent versions
  of the JSON library
- Avoid ArgumentError when no HOME environment variable is set
- Add Resource::Organization proxy
- Update all comments to point to the correct Docs site URLs

## v0.6.0 (2016-05-05)

- Remove support for Ruby 1.9
- Add the ability to disable signing on a request
- Always send JSON when authenticating a user
- Fix to_json method contract
- Add config file support. See the readme for an example
- Add required fields to role schema
- Do not symbolize keys in the config
- Fix boolean logic in determining if SSL should be verified

## v0.5.0 (2014-07-10)

- Relax the dependency on mime-types
- When searching for the file object of a multipart filepart, find the first IO that not a StringIO
- Rewind IO objects after digesting them

## v0.4.1 (2014-07-07)

- Remove dependency on mixlib-authentication
- Fix a bug where Content-Type headers were not sent properly
- Switch to rake for test running
- Improve test coverage with fixtures

## v0.4.0 (2014-07-05)

- Support multipart POST

## v0.3.0 (2014-06-18)

- Add search functionality
- Add partial search
- Update testing harness

## v0.2.1 (2014-04-17)

- Fix a series of typographical errors
- Improved documentation for loading resources from disk
- Improved spec coverage
- Switch to Logify for logging
- Add HEC endpoint for authenticating users
- Change the default options for Hosted Chef
- Implement HTTPGatewayTimeout (504)
- Do not automatically inflate JSON objects
- Improved logging awesomeness
- Add "flavors" when defining the schema (OSC is different than HEC)
- Remove i18n in favor of ERB
- Fix an issue when providing a key at an unexpanded path
