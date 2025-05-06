# frozen_string_literal: true

require 'spec_helper'

describe Mongoid::RelationsDirtyTracking do
  subject(:doc) { TestDocument.create }

  its(:changed?)                { is_expected.to be false }
  its(:children_changed?)       { is_expected.to be false }
  its(:relations_changed?)      { is_expected.to be false }
  its(:changed_with_relations?) { is_expected.to be false }

  context 'embeds_one relationship' do
    context 'when adding document' do
      before do
        @embedded_doc = TestEmbeddedDocument.new
        subject.one_document = @embedded_doc
      end

      its(:changed?)                { is_expected.to be false }
      its(:children_changed?)       { is_expected.to be false }
      its(:relations_changed?)      { is_expected.to be true }
      its(:changed_with_relations?) { is_expected.to be true }
      its(:changes_with_relations)  { is_expected.to include(subject.relation_changes) }

      describe '#relation_changes' do
        it 'returns array with differences' do
          expect(subject.relation_changes['one_document']).to eq([nil, @embedded_doc.attributes])
        end
      end
    end

    context 'when removing document' do
      before do
        @embedded_doc = TestEmbeddedDocument.new
        subject.one_document = @embedded_doc
        subject.save!
        subject.one_document = nil
      end

      its(:changed?)                { is_expected.to be false }
      its(:children_changed?)       { is_expected.to be false }
      its(:relations_changed?)      { is_expected.to be true }
      its(:changed_with_relations?) { is_expected.to be true }
      its(:changes_with_relations)  { is_expected.to include(subject.relation_changes) }

      describe '#relation_changes' do
        it 'returns array with differences' do
          expect(subject.relation_changes['one_document']).to eq([@embedded_doc.attributes, nil])
        end
      end
    end

    context 'when changing value on embedded document' do
      before do
        @embedded_doc = TestEmbeddedDocument.new
        subject.one_document = @embedded_doc
        subject.save!
        subject.one_document.title = 'foobar'
      end

      its(:changed?)                { is_expected.to be true }
      its(:children_changed?)       { is_expected.to be true }
      its(:relations_changed?)      { is_expected.to be true }
      its(:changed_with_relations?) { is_expected.to be true }
      its(:changes_with_relations)  { is_expected.to include(subject.relation_changes) }

      describe '#relation_changes' do
        it 'returns array with differences' do
          old_attributes = @embedded_doc.attributes.clone.delete_if { |key, _val| key == 'title' }
          expect(subject.relation_changes['one_document']).to eq([old_attributes, @embedded_doc.attributes])
        end
      end
    end

    context 'when just updated_at is changed on embedded document' do
      before do
        embedded_doc = Class.new(TestEmbeddedDocument) { include Mongoid::Timestamps }.new
        subject.one_document = @embedded_doc
        subject.save!
        embedded_doc.updated_at = Time.now
      end

      its(:changed?) { is_expected.to be false }
    end
  end

  context 'embeds_many relationship' do
    context 'when adding document' do
      before do
        @embedded_doc = TestEmbeddedDocument.new
        subject.many_documents << @embedded_doc
      end

      its(:changed?)                { is_expected.to be false }
      its(:children_changed?)       { is_expected.to be false }
      its(:relations_changed?)      { is_expected.to be true }
      its(:changed_with_relations?) { is_expected.to be true }
      its(:changes_with_relations)  { is_expected.to include(subject.relation_changes) }

      describe '#relation_changes' do
        it 'returns array with differences' do
          expect(subject.relation_changes['many_documents']).to eq([[], [@embedded_doc.attributes]])
        end
      end
    end

    context 'when removing document' do
      before do
        @embedded_doc = TestEmbeddedDocument.new
        subject.many_documents = [@embedded_doc]
        subject.save!
        subject.many_documents.delete @embedded_doc
      end

      its(:changed?)                { is_expected.to be false }
      its(:children_changed?)       { is_expected.to be false }
      its(:relations_changed?)      { is_expected.to be true }
      its(:changed_with_relations?) { is_expected.to be true }
      its(:changes_with_relations)  { is_expected.to include(subject.relation_changes) }

      describe '#relation_changes' do
        it 'returns array with differences' do
          expect(subject.relation_changes['many_documents']).to eq([[@embedded_doc.attributes], []])
        end
      end
    end
  end

  context 'has_one relationship' do
    context 'when adding document' do
      before do
        @related_doc = TestRelatedDocument.new
        subject.one_related = @related_doc
      end

      its(:changed?)                { is_expected.to be false }
      its(:children_changed?)       { is_expected.to be false }
      its(:relations_changed?)      { is_expected.to be true }
      its(:changed_with_relations?) { is_expected.to be true }
      its(:changes_with_relations)  { is_expected.to include(subject.relation_changes) }

      describe '#relation_changes' do
        it 'returns array with differences' do
          expect(subject.relation_changes['one_related']).to eq([nil, { '_id' => @related_doc._id }])
        end
      end
    end

    context 'when removing document' do
      before do
        @related_doc = TestRelatedDocument.new
        subject.one_related = @related_doc
        subject.save!
        subject.one_related = nil
      end

      its(:changed?)                { is_expected.to be false }
      its(:children_changed?)       { is_expected.to be false }
      its(:relations_changed?)      { is_expected.to be true }
      its(:changed_with_relations?) { is_expected.to be true }
      its(:changes_with_relations)  { is_expected.to include(subject.relation_changes) }

      describe '#relation_changes' do
        it 'returns array with differences' do
          expect(subject.relation_changes['one_related']).to eq([{ '_id' => @related_doc._id }, nil])
        end
      end
    end

    context 'when changing document' do
      before do
        @related_doc = TestRelatedDocument.new
        subject.one_related = @related_doc
        subject.save!
        subject.one_related = @another_related_doc = TestRelatedDocument.new
      end

      its(:changed?)                { is_expected.to be false }
      its(:children_changed?)       { is_expected.to be false }
      its(:relations_changed?)      { is_expected.to be true }
      its(:changed_with_relations?) { is_expected.to be true }
      its(:changes_with_relations)  { is_expected.to include(subject.relation_changes) }

      describe '#relation_changes' do
        it 'returns array with differences' do
          expect(subject.relation_changes['one_related']).to eq([{ '_id' => @related_doc._id },
                                                                 { '_id' => @another_related_doc._id }])
        end
      end
    end

    context 'when changing value on referenced document' do
      before do
        @related_doc = TestRelatedDocument.new
        subject.one_related = @related_doc
        subject.save!
        subject.one_related.title = 'New title'
      end

      its(:changed?)                { is_expected.to be false }
      its(:children_changed?)       { is_expected.to be false }
      its(:relations_changed?)      { is_expected.to be false }
      its(:changed_with_relations?) { is_expected.to be false }
      its(:relation_changes)        { is_expected.to be_empty }
    end
  end

  context 'has_many relationship' do
    context 'when adding document' do
      before do
        @related_doc = TestRelatedDocument.new
        subject.many_related << @related_doc
      end

      its(:changed?)                { is_expected.to be false }
      its(:children_changed?)       { is_expected.to be false }
      its(:relations_changed?)      { is_expected.to be true }
      its(:changed_with_relations?) { is_expected.to be true }
      its(:changes_with_relations)  { is_expected.to include(subject.relation_changes) }

      describe '#relation_changes' do
        it 'returns array with differences' do
          expect(subject.relation_changes['many_related']).to eq([[], [{ '_id' => @related_doc._id }]])
        end
      end
    end

    context 'when removing document' do
      before do
        @related_doc = TestRelatedDocument.new
        subject.many_related << @related_doc
        subject.save!
        subject.many_related.delete(@related_doc)
      end

      its(:changed?)                { is_expected.to be false }
      its(:children_changed?)       { is_expected.to be false }
      its(:relations_changed?)      { is_expected.to be true }
      its(:changed_with_relations?) { is_expected.to be true }
      its(:changes_with_relations)  { is_expected.to include(subject.relation_changes) }

      describe '#relation_changes' do
        it 'returns array with differences' do
          expect(subject.relation_changes['many_related']).to eq([[{ '_id' => @related_doc._id }], []])
        end
      end
    end
  end

  context 'has_and_belongs_to_many relationship' do
    context 'when adding document' do
      before do
        @related_doc = TestRelatedDocument.new
        subject.many_to_many_related << @related_doc
      end

      its(:changed?)                { is_expected.to be false }
      its(:children_changed?)       { is_expected.to be false }
      its(:relations_changed?)      { is_expected.to be true }
      its(:changed_with_relations?) { is_expected.to be true }
      its(:changes_with_relations)  { is_expected.to include(subject.relation_changes) }

      describe '#relation_changes' do
        it 'returns array with differences' do
          expect(subject.relation_changes['many_to_many_related']).to eq([[], [{ '_id' => @related_doc._id }]])
        end
      end
    end

    context 'when removing document' do
      before do
        @related_doc = TestRelatedDocument.new
        subject.many_to_many_related << @related_doc
        subject.save!
        subject.many_to_many_related.delete(@related_doc)
      end

      its(:changed?)                { is_expected.to be false }
      its(:children_changed?)       { is_expected.to be false }
      its(:relations_changed?)      { is_expected.to be true }
      its(:changed_with_relations?) { is_expected.to be true }
      its(:changes_with_relations)  { is_expected.to include(subject.relation_changes) }

      describe '#relation_changes' do
        it 'returns array with differences' do
          expect(subject.relation_changes['many_to_many_related']).to eq([[{ '_id' => @related_doc._id }], []])
        end
      end
    end
  end

  context 'belongs_to relationship' do
    subject { TestRelatedDocument.create }

    context 'when adding document' do
      before do
        @doc = TestDocument.create
        subject.test_document = @doc
      end

      its(:changed?)                { is_expected.to be true }
      its(:children_changed?)       { is_expected.to be false }
      its(:relations_changed?)      { is_expected.to be true }
      its(:changed_with_relations?) { is_expected.to be true }
      its(:changes_with_relations)  { is_expected.to include(subject.relation_changes) }

      describe '#relation_changes' do
        it 'returns array with differences' do
          expect(subject.relation_changes['test_document']).to eq([nil, { 'test_document_id' => @doc._id }])
        end
      end
    end

    context 'when removing document' do
      before do
        @doc = TestDocument.create
        subject.test_document = @doc
        subject.save!
        subject.test_document = nil
      end

      its(:changed?)                { is_expected.to be true }
      its(:children_changed?)       { is_expected.to be false }
      its(:relations_changed?)      { is_expected.to be true }
      its(:changed_with_relations?) { is_expected.to be true }
      its(:changes_with_relations)  { is_expected.to include(subject.relation_changes) }

      describe '#relation_changes' do
        it 'returns array with differences' do
          expect(subject.relation_changes['test_document']).to eq([{ 'test_document_id' => @doc._id }, nil])
        end
      end
    end
  end

  describe '.track_relation?' do
    context 'with only options' do
      it 'do tracks only specified relations' do
        expect(TestDocumentWithOnlyOption.track_relation?(:many_documents)).to be true
        expect(TestDocumentWithOnlyOption.track_relation?(:one_related)).to be false
      end
    end

    context 'with except options' do
      it 'do no track excluded relations' do
        expect(TestDocumentWithExceptOption.track_relation?('many_documents')).to be false
        expect(TestDocumentWithExceptOption.track_relation?('one_related')).to be true
      end
    end
  end

  describe 'by default the versions relation is not tracked' do
    context "when not called 'relations_dirty_tracking'" do
      it "'versions' is excluded from tracing" do
        expect(Class.new(TestDocument).relations_dirty_tracking_options[:except]).to include('versions')
      end
    end

    context "when called 'relations_dirty_tracking' with only" do
      it "'versions' is excluded from tracing" do
        klass = Class.new(TestDocument) { relations_dirty_tracking(only: 'foobar') }
        expect(klass.relations_dirty_tracking_options[:except]).to include('versions')
      end
    end

    context "when called 'relations_dirty_tracking' with except" do
      it "'versions' is excluded from tracing" do
        klass = Class.new(TestDocument) { relations_dirty_tracking(except: 'foobar') }
        expect(klass.relations_dirty_tracking_options[:except]).to include('versions')
        expect(klass.relations_dirty_tracking_options[:except]).to include('foobar')
      end
    end
  end

  describe 'disable if readonly?' do
    subject do
      doc
      TestDocument.all.only(:one_related_id).first
    end

    before do
      @embedded_doc = TestEmbeddedDocument.new

      subject.many_documents << @embedded_doc
    end

    its(:changed?)                { is_expected.to be false }
    its(:children_changed?)       { is_expected.to be false }
    its(:relations_changed?)      { is_expected.to be false }
    its(:changed_with_relations?) { is_expected.to be false }
    its(:changes_with_relations)  { is_expected.to_not include(subject.relation_changes) }

    describe '#relation_changes' do
      it 'returns array with differences' do
        expect(subject.relation_changes['many_documents']).to be_nil
      end
    end
  end

  describe 'global disablement' do
    before do
      @embedded_doc = TestEmbeddedDocument.new

      described_class.disable do
        subject.many_documents << @embedded_doc
      end
    end

    its(:changed?)                { is_expected.to be false }
    its(:children_changed?)       { is_expected.to be false }
    its(:relations_changed?)      { is_expected.to be false }
    its(:changed_with_relations?) { is_expected.to be false }
    its(:changes_with_relations)  { is_expected.to_not include(subject.relation_changes) }

    describe '#relation_changes' do
      it 'returns array with differences' do
        expect(subject.relation_changes['many_documents']).to be_nil
      end
    end
  end
end
