# frozen_string_literal: true

require 'mongoid'
require 'active_support/concern'

module Mongoid
  module RelationsDirtyTracking
    extend ActiveSupport::Concern

    class << self
      DISABLED_KEY = 'mongoid/relations_dirty_tracking/disabled'

      # Runs a block without invoking relations dirty tracking on the current thread.
      # Returns the block return value.
      def disable
        thread_store[DISABLED_KEY] = true
        yield
      ensure
        thread_store[DISABLED_KEY] = false
      end

      # Returns whether relations dirty tracking is enabled on the current thread.
      def enabled?
        !thread_store[DISABLED_KEY]
      end

      protected

      def thread_store
        defined?(RequestStore) ? RequestStore.store : Thread.current
      end
    end

    module ClassMethods
      def relations_dirty_tracking(options = {})
        relations_dirty_tracking_options[:only]   += [options[:only]   || []].flatten.map(&:to_s)
        relations_dirty_tracking_options[:except] += [options[:except] || []].flatten.map(&:to_s)
      end

      def track_relation?(rel_name)
        rel_name = rel_name.to_s
        options = relations_dirty_tracking_options
        to_track = (!options[:only].blank? && options[:only].include?(rel_name)) ||
                   (options[:only].blank? && !options[:except].include?(rel_name))

        trackables = [Mongoid::Association::Embedded::EmbedsOne::Proxy,
                      Mongoid::Association::Embedded::EmbedsMany::Proxy,
                      Mongoid::Association::Referenced::HasOne::Proxy,
                      Mongoid::Association::Referenced::HasMany::Proxy,
                      Mongoid::Association::Referenced::HasAndBelongsToMany::Proxy,
                      Mongoid::Association::Referenced::BelongsTo::Proxy]

        to_track && trackables.include?(relations[rel_name].try(:relation))
      end

      def tracked_relations
        @tracked_relations ||= relations.keys.select { |rel_name| track_relation?(rel_name) }
      end
    end

    included do
      after_initialize :store_relations_shadow
      after_save       :store_relations_shadow

      cattr_accessor :relations_dirty_tracking_options
      self.relations_dirty_tracking_options = { only: [], except: ['versions'] }

      def store_relations_shadow
        @relations_shadow = {}
        return if readonly? || !Mongoid::RelationsDirtyTracking.enabled?
        self.class.tracked_relations.each do |rel_name|
          next if attribute_missing?(rel_name)
          @relations_shadow[rel_name] = tracked_relation_attributes(rel_name)
        end
      end

      def relation_changes
        return {} if readonly? || !Mongoid::RelationsDirtyTracking.enabled?
        changes = {}
        @relations_shadow.each_pair do |rel_name, shadow_values|
          current_values = tracked_relation_attributes(rel_name)
          changes[rel_name] = [shadow_values, current_values] if current_values != shadow_values
        end
        changes
      end

      def relations_changed?
        !relation_changes.empty?
      end

      def changed_with_relations?
        changed? || relations_changed?
      end

      def changes_with_relations
        (changes || {}).merge(relation_changes)
      end

      def tracked_relation_attributes(rel_name)
        rel_name = rel_name.to_s
        meta = relations[rel_name]
        return nil unless meta
        case meta
        when Mongoid::Association::Embedded::EmbedsOne
          val = send(rel_name)
          val && val.attributes.clone.delete_if { |key, _| key == 'updated_at' }
        when Mongoid::Association::Embedded::EmbedsMany
          val = send(rel_name)
          val && val.map { |child| child.attributes.clone.delete_if { |key, _| key == 'updated_at' } }
        when Mongoid::Association::Referenced::HasOne
          send(rel_name) && { meta.key.to_s => send(rel_name)[meta.key] }
        when Mongoid::Association::Referenced::HasMany
          send(rel_name).map { |child| { meta.key.to_s => child.id } }
        when Mongoid::Association::Referenced::HasAndBelongsToMany
          send(rel_name).map { |child| { meta.primary_key.to_s => child.id } }
        when Mongoid::Association::Referenced::BelongsTo
          send(meta.foreign_key) && { meta.foreign_key.to_s => send(meta.foreign_key) }
        end
      end
    end
  end
end
