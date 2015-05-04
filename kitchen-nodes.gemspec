# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kitchen/provisioner/nodes_version'

Gem::Specification.new do |spec|
  spec.name          = 'kitchen-nodes'
  spec.version       = Kitchen::Provisioner::NODES_VERSION
  spec.authors       = ['Matt Wrock']
  spec.email         = ['matt@mattwrock.com']
  spec.description   = %q{A Test Kitchen Provisioner for Chef Nodes}
  spec.summary       = spec.description
  spec.homepage      = ''
  spec.license       = 'Apache 2.0'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = []
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'net-ping'
  spec.add_dependency 'win32-security'
  spec.add_dependency 'test-kitchen', '~> 1.4'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency "fakefs",    "~> 0.4"
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 3.2'
end
