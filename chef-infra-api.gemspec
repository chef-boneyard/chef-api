lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "chef-api/version"

Gem::Specification.new do |spec|
  spec.name          = "chef-infra-api"
  spec.version       = ChefAPI::VERSION
  spec.authors       = ["Seth Vargo", "Tim Smith"]
  spec.email         = ["sethvargo@gmail.com", "tsmith84@gmail.com"]
  spec.description   = "A tiny Chef Infra API client with minimal dependencies"
  spec.summary       = "A Chef Infra API client in Ruby"
  spec.homepage      = "https://github.com/chef/chef-api"
  spec.license       = "Apache-2.0"

  spec.required_ruby_version = ">= 2.3"

  spec.files         = %w{LICENSE} + Dir.glob("{lib,templates}/**/*", File::FNM_DOTMATCH).reject { |f| File.directory?(f) }
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "mixlib-log", ">= 1", "< 4" # we need to validate 4.x before we loosen this
  spec.add_dependency "mime-types"
end
