# frozen_string_literal: true

require_relative 'lib/mongoid/relations_dirty_tracking/version'

Gem::Specification.new do |spec|
  spec.name          = 'mongoid_relations_dirty_tracking'
  spec.version       = Mongoid::RelationsDirtyTracking::VERSION
  spec.authors       = ['David Sevcik']
  spec.email         = ['david.sevcik@gmail.com']
  spec.description   = 'Mongoid extension for tracking changes on document relations'
  spec.summary       = 'Mongoid extension for tracking changes on document relations'
  spec.homepage      = 'https://github.com/tablecheck/mongoid_relations_dirty_tracking'
  spec.license       = 'MIT'

  spec.add_dependency 'mongoid', '>= 9.0'

  spec.files         = Dir.glob('lib/**/*') + %w[LICENSE README.md]
  spec.require_paths = ['lib']
  spec.metadata['rubygems_mfa_required'] = 'true'
end
