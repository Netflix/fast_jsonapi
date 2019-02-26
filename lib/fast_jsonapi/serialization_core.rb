# frozen_string_literal: true

require "active_support/concern"
require "fast_jsonapi/multi_to_json"

module FastJsonapi
  MandatoryField = Class.new(StandardError)

  module SerializationCore
    extend ActiveSupport::Concern

    included do
      class << self
        attr_accessor :attributes_to_serialize,
                      :relationships_to_serialize,
                      :cachable_relationships_to_serialize,
                      :uncachable_relationships_to_serialize,
                      :transform_method,
                      :record_type,
                      :record_id,
                      :cache_length,
                      :race_condition_ttl,
                      :cached,
                      :data_links,
                      :meta_to_serialize
      end
    end

    class_methods do
      def id_hash(id, default_return = false)
        if id.present?
          { id: id }
        else
          default_return ? { id: nil } : nil
        end
      end

      def links_hash(record, params = {})
        data_links.each_with_object({}) do |(_k, link), hash|
          link.serialize(record, params, hash)
        end
      end

      def attributes_hash(record, fieldset = nil, params = {})
        attributes = attributes_to_serialize
        attributes = attributes.slice(*fieldset) if fieldset.present?
        attributes.each_with_object({}) do |(_k, attribute), hash|
          attribute.serialize(record, params, hash)
        end
      end

      def relationships_hash(record, relationships = nil, fieldset = nil, params = {})
        relationships ||= relationships_to_serialize
        relationships = relationships.slice(*fieldset) if fieldset.present?

        relationships.each_with_object({}) do |(_k, relationship), hash|
          relationship.serialize(record, params, hash)
        end
      end

      def meta_hash(record, params = {})
        meta_to_serialize.call(record, params)
      end

      def record_hash(record, fieldset, params = {})
        if cached
          record_hash = Rails.cache.fetch(record.cache_key, expires_in: cache_length, race_condition_ttl: race_condition_ttl) do
            id_hash(id_from_record(record), true).tap do |hash|
              hash.merge! attributes_hash(record, fieldset, params) if attributes_to_serialize.present?
              hash.merge! relationships_hash(record, cachable_relationships_to_serialize, fieldset, params) if cachable_relationships_to_serialize.present?
              hash.merge! links_hash(record, params) if data_links.present?
            end
          end
          record_hash.merge! relationships_hash(record, uncachable_relationships_to_serialize, fieldset, params) if uncachable_relationships_to_serialize.present?
        else
          record_hash = id_hash(id_from_record(record), true)
          record_hash.merge! attributes_hash(record, fieldset, params) if attributes_to_serialize.present?
          record_hash.merge! relationships_hash(record, nil, fieldset, params) if relationships_to_serialize.present?
          record_hash.merge! links_hash(record, params) if data_links.present?
        end

        record_hash[:meta] = meta_hash(record, params) if meta_to_serialize.present?
        record_hash
      end

      def id_from_record(record)
        return record_id.call(record) if record_id.is_a?(Proc)
        return record.public_send(record_id) if record_id
        raise MandatoryField, "id is a mandatory field in the jsonapi spec" unless record.respond_to?(:id)

        record.id
      end

      # Override #to_json for alternative implementation
      def to_json(payload)
        FastJsonapi::MultiToJson.to_json(payload) if payload.present?
      end

      def remaining_items(items)
        return unless items.size > 1

        items_copy = items.dup
        items_copy.delete_at(0)
        [items_copy.join(".").to_sym]
      end

      def get_included_records(record, includes_list, known_included_objects, fieldsets, params = {})
        return unless includes_list.present?

        includes_list.each_with_object({}) do |(item, rest), included_records|
          next unless relationships_to_serialize &&
                      (relationship = relationships_to_serialize[item]) &&
                      relationship.include_relationship?(record, params)

          unless relationship.polymorphic.is_a?(Hash)
            record_type = relationship.record_type
            serializer = relationship.serializer.to_s.constantize
          end

          relationship_type = relationship.relationship_type
          included_objects = relationship.fetch_associated_object(record, params)
          next if included_objects.blank?

          Array.wrap(included_objects).each do |object|
            if relationship.polymorphic.is_a?(Hash)
              record_type = object.class.name.demodulize.underscore
              serializer = compute_serializer_name(object.class.name.demodulize.to_sym).to_s.constantize
            end

            code = "#{record_type}_#{serializer.id_from_record(object)}"
            next if known_included_objects.key?(code)

            known_included_objects[code] = object

            fetched_records = serializer.get_included_records(object, rest, known_included_objects, fieldsets, params)

            if relationship_type == :has_many
              included_records[item] ||= []
              included_records[item] << serializer.record_hash(object, fieldsets[serializer.record_type], params)
              substitute(item, included_records, fetched_records) if fetched_records.present?
            else
              included_records[item] = serializer.record_hash(object, fieldsets[serializer.record_type], params)
              included_records[item].merge! fetched_records if fetched_records.present?
            end
          end
        end
      end

      def substitute(item, records, replacements)
        replacements.each do |key, replacement|
          related = records[item].last
          if related[key].respond_to? :merge!
            related[key].merge! replacement
          else
            related[key] = replacement
          end
        end
      end
    end
  end
end
