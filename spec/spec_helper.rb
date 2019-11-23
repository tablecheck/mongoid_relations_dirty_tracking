# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'
require 'rspec'
require 'rspec/its'
require 'mongoid'
require 'mongoid/relations_dirty_tracking'

Mongo::Logger.logger.level = 2

Mongoid.configure do |config|
  config.logger.level = 2
  config.connect_to('mongoid_relations_dirty_tracking_test')
  config.belongs_to_required_by_default = false
end

RSpec.configure do |config|
  config.mock_with :rspec
  config.after(:all) { Mongoid.purge! }
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
