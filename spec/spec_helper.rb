# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'
require 'rspec'
require 'rspec/its'
require 'mongoid'
require 'mongoid/relations_dirty_tracking'

RSpec.configure do |config|
  config.disable_monkey_patching!

  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  # TODO: Currently the order matters in the specs
  # config.order = :random

  config.after(:all) { Mongoid.purge! }
end

Mongoid.configure do |config|
  config.connect_to('mongoid_relations_dirty_tracking_test')
  config.belongs_to_required_by_default = false
end

class TestDocument
  include Mongoid::Document
  include Mongoid::RelationsDirtyTracking

  embeds_one  :one_document,   class_name: 'TestEmbeddedDocument'
  embeds_many :many_documents, class_name: 'TestEmbeddedDocument'

  has_one     :one_related,    class_name: 'TestRelatedDocument'
  has_many    :many_related,   class_name: 'TestRelatedDocument'
  has_and_belongs_to_many :many_to_many_related, class_name: 'TestRelatedDocument'
end

class TestEmbeddedDocument
  include Mongoid::Document

  embedded_in :test_document

  field :title, type: String
end

class TestRelatedDocument
  include Mongoid::Document
  include Mongoid::RelationsDirtyTracking

  belongs_to :test_document, inverse_of: :one_related

  field :title, type: String
end

class TestDocumentWithOnlyOption
  include Mongoid::Document
  include Mongoid::RelationsDirtyTracking

  embeds_many :many_documents,  class_name: 'TestEmbeddedDocument'
  has_one     :one_related,     class_name: 'TestRelatedDocument'

  relations_dirty_tracking only: :many_documents
end

class TestDocumentWithExceptOption
  include Mongoid::Document
  include Mongoid::RelationsDirtyTracking

  embeds_many :many_documents,  class_name: 'TestEmbeddedDocument'
  has_one     :one_related,     class_name: 'TestRelatedDocument'

  relations_dirty_tracking except: 'many_documents'
end
