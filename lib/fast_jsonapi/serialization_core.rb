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
                      :cached
      end
    end

    class_methods do
      def id_hash(id, record_type)
        { id: id.to_s, type: record_type } if id.present?
      end

      def ids_hash(ids, record_type)
        return ids.map { |id| id_hash(id, record_type) } if ids.respond_to? :map
        id_hash(ids, record_type) # ids variable is just a single id here
      end

      def id_hash_from_record(record, record_types)
        # memoize the record type within the record_types dictionary, then assigning to record_type:
        record_type = record_types[record.class] ||= record.class.name.underscore.to_sym
        { id: record.id.to_s, type: record_type }
      end

      def ids_hash_from_record_and_relationship(record, relationship)
        polymorphic = relationship[:polymorphic]

        return ids_hash(
          record.public_send(relationship[:id_method_name]),
          relationship[:record_type]
        ) unless polymorphic

        return unless associated_object = record.send(relationship[:object_method_name])

        return associated_object.map do |object|
          id_hash_from_record object, polymorphic
        end if associated_object.respond_to? :map

        id_hash_from_record associated_object, polymorphic
      end

      def attributes_hash(record, params = {})
        attributes_to_serialize.each_with_object({}) do |(key, method), attr_hash|
          attr_hash[key] = if method.is_a?(Proc)
            method.arity == 1 ? method.call(record) : method.call(record, params)
          else
            record.public_send(method)
          end
        end
      end

      def relationships_hash(record, relationships = nil)
        relationships = relationships_to_serialize if relationships.nil?

        relationships.each_with_object({}) do |(_k, relationship), hash|
          name = relationship[:key]
          empty_case = relationship[:relationship_type] == :has_many ? [] : nil
          hash[name] = {
            data: ids_hash_from_record_and_relationship(record, relationship) || empty_case
          }
        end
      end

      def record_hash(record, params = {})
        if cached
          record_hash = Rails.cache.fetch(record.cache_key, expires_in: cache_length, race_condition_ttl: race_condition_ttl) do
            temp_hash = id_hash(id_from_record(record), record_type) || { id: nil, type: record_type }
            temp_hash[:attributes] = attributes_hash(record, params) if attributes_to_serialize.present?
            temp_hash[:relationships] = {}
            temp_hash[:relationships] = relationships_hash(record, cachable_relationships_to_serialize) if cachable_relationships_to_serialize.present?
            temp_hash
          end
          record_hash[:relationships] = record_hash[:relationships].merge(relationships_hash(record, uncachable_relationships_to_serialize)) if uncachable_relationships_to_serialize.present?
          record_hash
        else
          record_hash = id_hash(id_from_record(record), record_type) || { id: nil, type: record_type }
          record_hash[:attributes] = attributes_hash(record, params) if attributes_to_serialize.present?
          record_hash[:relationships] = relationships_hash(record) if relationships_to_serialize.present?
          record_hash
        end
      end

      def id_from_record(record)
         return record.send(record_id) if record_id
         raise MandatoryField, 'id is a mandatory field in the jsonapi spec' unless record.respond_to?(:id)
         record.id
      end

      # Override #to_json for alternative implementation
      def to_json(payload)
        FastJsonapi::MultiToJson.to_json(payload) if payload.present?
      end

      # includes handler

      def get_included_records(record, includes_list, known_included_objects)
        includes_list.each_with_object([]) do |item, included_records|
          object_method_name = @relationships_to_serialize[item][:object_method_name]
          record_type = @relationships_to_serialize[item][:record_type]
          serializer = @relationships_to_serialize[item][:serializer].to_s.constantize
          relationship_type = @relationships_to_serialize[item][:relationship_type]
          included_objects = record.send(object_method_name)
          next if included_objects.blank?
          included_objects = [included_objects] unless relationship_type == :has_many
          included_objects.each do |inc_obj|
            code = "#{record_type}_#{inc_obj.id}"
            next if known_included_objects.key?(code)
            known_included_objects[code] = inc_obj
            included_records << serializer.record_hash(inc_obj)
          end
        end
      end
    end
  end
end
