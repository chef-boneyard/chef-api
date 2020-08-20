# ChefAPI Changelog
<!-- latest_release 0.10.9 -->
## [v0.10.9](https://github.com/chef/chef-api/tree/v0.10.9) (2020-08-20)

#### Merged Pull Requests
- Fix chefstyle violations. [#94](https://github.com/chef/chef-api/pull/94) ([phiggins](https://github.com/phiggins))
<!-- latest_release -->
<!-- release_rollup since=0.10.7 -->
### Changes not yet released to rubygems.org

#### Merged Pull Requests
- Fix chefstyle violations. [#94](https://github.com/chef/chef-api/pull/94) ([phiggins](https://github.com/phiggins)) <!-- 0.10.9 -->
- Avoid Ruby 2.7 deprecation warnings by switching to CGI [#91](https://github.com/chef/chef-api/pull/91) ([tas50](https://github.com/tas50)) <!-- 0.10.8 -->
<!-- release_rollup -->

<!-- latest_stable_release -->
## [v0.10.7](https://github.com/chef/chef-api/tree/v0.10.7) (2020-06-12)

#### Merged Pull Requests
- Fix an undefined variable error in Validator::Type [#89](https://github.com/chef/chef-api/pull/89) ([yuta1024](https://github.com/yuta1024))
- Pin pry-stack-explorer and fix indentation [#90](https://github.com/chef/chef-api/pull/90) ([tas50](https://github.com/tas50))
<!-- latest_stable_release -->

## [v0.10.5](https://github.com/chef/chef-api/tree/v0.10.5) (2020-01-29)

#### Merged Pull Requests
- Switch logging to mixlib-log instead of logify [#85](https://github.com/chef/chef-api/pull/85) ([tecracer-theinen](https://github.com/tecracer-theinen))
- Loosen the mixlib-log dep to allow for older ruby releases [#86](https://github.com/chef/chef-api/pull/86) ([tas50](https://github.com/tas50))
- Test on Ruby 2.7 and test on Windows [#87](https://github.com/chef/chef-api/pull/87) ([tas50](https://github.com/tas50))

## [v0.10.2](https://github.com/chef/chef-api/tree/v0.10.2) (2019-12-21)

#### Merged Pull Requests
- Apply chefstyle to this repo [#79](https://github.com/chef/chef-api/pull/79) ([tas50](https://github.com/tas50))
- Substitute require for require_relative [#84](https://github.com/chef/chef-api/pull/84) ([tas50](https://github.com/tas50))

## [v0.10.0](https://github.com/chef/chef-api/tree/v0.10.0) (2019-10-18)

#### Merged Pull Requests
- Wire up Expeditor to release chef-api and chef-infra-api [#77](https://github.com/chef/chef-api/pull/77) ([tas50](https://github.com/tas50))
- Require Ruby 2.3+ and remove travis config [#78](https://github.com/chef/chef-api/pull/78) ([tas50](https://github.com/tas50))

## v0.9.0 (2018-12-03)

- Removed support for the EOL Ruby 2.1 release
- Removed the note about heavy development in the readme
- Updated the gemspec to use a SPDX compliant license string
- Slimmed the gem down to only ship the necessary files for execution vs. full development

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