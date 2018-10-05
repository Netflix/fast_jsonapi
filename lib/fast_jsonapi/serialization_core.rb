# frozen_string_literal: true

require 'active_support/concern'
require 'fast_jsonapi/multi_to_json'

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
      def id_hash(id, record_type, default_return=false)
        if id.present?
          { id: id.to_s, type: record_type }
        else
          default_return ? { id: nil, type: record_type } : nil
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
        relationships = relationships_to_serialize if relationships.nil?
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
            temp_hash = id_hash(id_from_record(record), record_type, true)
            temp_hash[:attributes] = attributes_hash(record, fieldset, params) if attributes_to_serialize.present?
            temp_hash[:relationships] = {}
            temp_hash[:relationships] = relationships_hash(record, cachable_relationships_to_serialize, fieldset, params) if cachable_relationships_to_serialize.present?
            temp_hash[:links] = links_hash(record, params) if data_links.present?
            temp_hash
          end
          record_hash[:relationships] = record_hash[:relationships].merge(relationships_hash(record, uncachable_relationships_to_serialize, fieldset, params)) if uncachable_relationships_to_serialize.present?
          record_hash[:meta] = meta_hash(record, params) if meta_to_serialize.present?
          record_hash
        else
          record_hash = id_hash(id_from_record(record), record_type, true)
          record_hash[:attributes] = attributes_hash(record, fieldset, params) if attributes_to_serialize.present?
          record_hash[:relationships] = relationships_hash(record, nil, fieldset, params) if relationships_to_serialize.present?
          record_hash[:links] = links_hash(record, params) if data_links.present?
          record_hash[:meta] = meta_hash(record, params) if meta_to_serialize.present?
          record_hash
        end
      end

      def id_from_record(record)
        return record_id.call(record) if record_id.is_a?(Proc)
        return record.send(record_id) if record_id
        raise MandatoryField, 'id is a mandatory field in the jsonapi spec' unless record.respond_to?(:id)
        record.id
      end

      # Override #to_json for alternative implementation
      def to_json(payload)
        FastJsonapi::MultiToJson.to_json(payload) if payload.present?
      end

      def parse_include_item(include_item)
        return [include_item.to_sym] unless include_item.to_s.include?('.')
        include_item.to_s.split('.').map { |item| item.to_sym }
      end

      def remaining_items(items)
        return unless items.size > 1

        items_copy = items.dup
        items_copy.delete_at(0)
        [items_copy.join('.').to_sym]
      end

      # includes handler
      def get_included_records(record, includes_list, known_included_objects, fieldsets, params = {})
        return unless includes_list.present?

        includes_list.sort.each_with_object([]) do |include_item, included_records|
          items = parse_include_item(include_item)
          items.each do |item|
            next unless relationships_to_serialize && relationships_to_serialize[item]
            relationship_item = relationships_to_serialize[item]
            next unless relationship_item.include_relationship?(record, params)
            unless relationship_item.polymorphic.is_a?(Hash)
              record_type = relationship_item.record_type
              serializer = relationship_item.serializer.to_s.constantize
            end
            relationship_type = relationship_item.relationship_type

            included_objects = relationship_item.fetch_associated_object(record, params)
            next if included_objects.blank?
            included_objects = [included_objects] unless relationship_type == :has_many

            included_objects.each do |inc_obj|
              if relationship_item.polymorphic.is_a?(Hash)
                record_type = inc_obj.class.name.demodulize.underscore
                serializer = self.compute_serializer_name(inc_obj.class.name.demodulize.to_sym).to_s.constantize
              end

              if remaining_items(items)
                serializer_records = serializer.get_included_records(inc_obj, remaining_items(items), known_included_objects, fieldsets, params)
                included_records.concat(serializer_records) unless serializer_records.empty?
              end

              code = "#{record_type}_#{serializer.id_from_record(inc_obj)}"
              next if known_included_objects.key?(code)

              known_included_objects[code] = inc_obj

              included_records << serializer.record_hash(inc_obj, fieldsets[serializer.record_type], params)
            end
          end
        end
      end
    end
  end
end
