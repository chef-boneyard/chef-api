ChefAPI Changelog
=================

v0.5.0 (2014-07-10)
-------------------
- Relax the dependency on mime-types
- When searching for the file object of a multipart filepart, find the first IO that not a StringIO
- Rewind IO objects after digesting them

v0.4.1 (2014-07-07)
-------------------
- Remove dependency on mixlib-authentication
- Fix a bug where Content-Type headers were not sent properly
- Switch to rake for test running
- Improve test coverage with fixtures

v0.4.0 (2014-07-05)
-------------------
- Support multipart POST

v0.3.0 (2014-06-18)
-------------------
- Add search functionality
- Add partial search
- Update testing harness


v0.2.1 (2014-04-17)
-------------------
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
