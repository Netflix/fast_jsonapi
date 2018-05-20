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
                      :data_links
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

      def ids_hash(ids, record_type)
        return ids.map { |id| id_hash(id, record_type) } if ids.respond_to? :map
        id_hash(ids, record_type) # ids variable is just a single id here
      end

      def id_hash_from_record(record, record_types)
        # memoize the record type within the record_types dictionary, then assigning to record_type:
        record_type = record_types[record.class] ||= record.class.name.underscore.to_sym
        id_hash(record.id, record_type)
      end

      def ids_hash_from_record_and_relationship(record, relationship, params = {})
        polymorphic = relationship[:polymorphic]

        return ids_hash(
          fetch_id(record, relationship, params),
          relationship[:record_type]
        ) unless polymorphic

        return unless associated_object = fetch_associated_object(record, relationship, params)

        return associated_object.map do |object|
          id_hash_from_record object, polymorphic
        end if associated_object.respond_to? :map

        id_hash_from_record associated_object, polymorphic
      end

      def links_hash(record, serializer_instance)
        @data_links.each_with_object({}) do |(key, method), link_hash|
          link_hash[key] = method.is_a?(Proc) ? serializer_instance.instance_exec(record, &method) : record.public_send(method)
        end
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

      def relationships_hash(record, relationships = nil, params = {})
        relationships = relationships_to_serialize if relationships.nil?

        relationships.each_with_object({}) do |(_k, relationship), hash|
          name = relationship[:key]
          empty_case = relationship[:relationship_type] == :has_many ? [] : nil
          hash[name] = {
            data: ids_hash_from_record_and_relationship(record, relationship, params) || empty_case
          }
        end
      end

      def record_hash(record, params = {}, serializer_instance)
        if cached
          record_hash = Rails.cache.fetch(record.cache_key, expires_in: cache_length, race_condition_ttl: race_condition_ttl) do
            temp_hash = id_hash(id_from_record(record), record_type, true)
            temp_hash[:attributes] = attributes_hash(record, params) if attributes_to_serialize.present?
            temp_hash[:relationships] = {}
            temp_hash[:relationships] = relationships_hash(record, cachable_relationships_to_serialize, params) if cachable_relationships_to_serialize.present?
            if @data_links.present?
              temp_links_hash = links_hash(record, serializer_instance)
              temp_hash[:links] = temp_links_hash if temp_links_hash
            end
            temp_hash
          end
          record_hash[:relationships] = record_hash[:relationships].merge(relationships_hash(record, uncachable_relationships_to_serialize, params)) if uncachable_relationships_to_serialize.present?
          record_hash
        else
          record_hash = id_hash(id_from_record(record), record_type, true)
          record_hash[:attributes] = attributes_hash(record, params) if attributes_to_serialize.present?
          record_hash[:relationships] = relationships_hash(record, nil, params) if relationships_to_serialize.present?
          if @data_links.present?
            temp_links_hash = links_hash(record, serializer_instance)
            record_hash[:links] = temp_links_hash if temp_links_hash
          end
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
      def get_included_records(record, includes_list, known_included_objects, params = {})
        return unless includes_list.present?

        includes_list.sort.each_with_object([]) do |include_item, included_records|
          items = parse_include_item(include_item)
          items.each do |item|
            next unless relationships_to_serialize && relationships_to_serialize[item]
            raise NotImplementedError if @relationships_to_serialize[item][:polymorphic].is_a?(Hash)
            record_type = @relationships_to_serialize[item][:record_type]
            serializer = @relationships_to_serialize[item][:serializer].to_s.constantize
            relationship_type = @relationships_to_serialize[item][:relationship_type]

            included_objects = fetch_associated_object(record, @relationships_to_serialize[item], params)
            next if included_objects.blank?
            included_objects = [included_objects] unless relationship_type == :has_many

            included_objects.each do |inc_obj|
              if remaining_items(items)
                serializer_records = serializer.get_included_records(inc_obj, remaining_items(items), known_included_objects)
                included_records.concat(serializer_records) unless serializer_records.empty?
              end

              code = "#{record_type}_#{inc_obj.id}"
              next if known_included_objects.key?(code)

              known_included_objects[code] = inc_obj
              included_records << serializer.record_hash(inc_obj, params, serializer.new(record))
            end
          end
        end
      end

      def fetch_associated_object(record, relationship, params)
        return relationship[:object_block].call(record, params) unless relationship[:object_block].nil?
        record.send(relationship[:object_method_name])
      end

      def fetch_id(record, relationship, params)
        unless relationship[:object_block].nil?
          object = relationship[:object_block].call(record, params)

          return object.map(&:id) if object.respond_to? :map
          return object.id
        end

        if relationship[:relationship_type] == :has_one
          record.public_send(relationship[:object_method_name]).try(:id)
        else
          record.public_send(relationship[:id_method_name])
        end
      end
    end
  end
end
