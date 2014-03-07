# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'chef-api/version'

Gem::Specification.new do |spec|
  spec.name          = 'chef-api'
  spec.version       = ChefAPI::VERSION
  spec.authors       = ['Seth Vargo']
  spec.email         = ['sethvargo@gmail.com']
  spec.description   = 'A tiny Chef API client with minimal dependencies'
  spec.summary       = 'A Chef API client in Ruby'
  spec.homepage      = 'https://github.com/sethvargo/chef-api'
  spec.license       = 'Apache 2.0'

  spec.required_ruby_version = '>= 1.9'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'i18n',                  '~> 0.6', '>= 0.6.6'
  spec.add_dependency 'mixlib-authentication', '~> 1.3'
end
