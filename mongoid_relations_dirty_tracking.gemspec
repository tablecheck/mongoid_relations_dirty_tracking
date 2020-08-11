# frozen_string_literal: true

require File.expand_path('lib/mongoid/relations_dirty_tracking/version', __dir__)

Gem::Specification.new do |spec|
  spec.name          = 'mongoid_relations_dirty_tracking'
  spec.version       = Mongoid::RelationsDirtyTracking::VERSION
  spec.authors       = ['David Sevcik']
  spec.email         = ['david.sevcik@gmail.com']
  spec.description   = 'Mongoid extension for tracking changes on document relations'
  spec.summary       = 'Mongoid extension for tracking changes on document relations'
  spec.homepage      = 'http://github.com/versative/relations_dirty_tracking'
  spec.license       = 'MIT'

  spec.add_runtime_dependency 'activesupport', '>= 5.1'
  spec.add_runtime_dependency 'mongoid', '>= 7.0'

  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 3.8.0'
  spec.add_development_dependency 'rspec-its', '~> 1.3'
  spec.add_development_dependency 'rubocop'

  spec.files         = Dir.glob('lib/**/*') + %w[LICENSE README.md]
  spec.test_files    = Dir.glob('spec/**/*')
  spec.require_paths = ['lib']
end
