require 'active_support/concern'
require 'fast_jsonapi/multi_to_json'

module FastJsonapi
  module SerializationCore
    extend ActiveSupport::Concern

    included do
      class << self
        attr_accessor :attributes_to_serialize,
                      :relationships_to_serialize,
                      :cachable_relationships_to_serialize,
                      :uncachable_relationships_to_serialize,
                      :record_type,
                      :cache_length,
                      :cached
      end

      attr_accessor :object

      def klass
        self.class
      end

      def attributes_hash(record)
        klass.attributes_to_serialize.each_with_object({}) do |(key, method_name), attr_hash|
          attr_hash[key] = send(method_name)
        end
      end

      def relationships_hash(record, relationships = nil)
        relationships = klass.relationships_to_serialize if relationships.nil?

        relationships.each_with_object({}) do |(_k, relationship), hash|
          name = relationship[:key]
          id_method_name = relationship[:id_method_name]
          record_type = relationship[:record_type]
          empty_case = relationship[:relationship_type] == :has_many ? [] : nil
          hash[name] = {
            data: klass.ids_hash(record.public_send(id_method_name), record_type) || empty_case
          }
        end
      end

      def record_hash(record)
        self.object = record
        if klass.cached
          record_hash = Rails.cache.fetch(record.cache_key, expires_in: klass.cache_length) do
            temp_hash = klass.id_hash(record.id, klass.record_type) || { id: nil, type: klass.record_type }
            temp_hash[:attributes] = attributes_hash(record) if klass.attributes_to_serialize.present?
            temp_hash[:relationships] = {}
            temp_hash[:relationships] = relationships_hash(record, klass.cachable_relationships_to_serialize) if klass.cachable_relationships_to_serialize.present?
            temp_hash
          end
          record_hash[:relationships] = record_hash[:relationships].merge(relationships_hash(record, klass.uncachable_relationships_to_serialize)) if klass.uncachable_relationships_to_serialize.present?
          record_hash
        else
          record_hash =klass.id_hash(record.id, klass.record_type) || { id: nil, type: klass.record_type }
          record_hash[:attributes] = attributes_hash(record) if klass.attributes_to_serialize.present?
          record_hash[:relationships] = relationships_hash(record) if klass.relationships_to_serialize.present?
          record_hash
        end
      end
    end

    class_methods do
      def id_hash(id, record_type)
        return { id: id.to_s, type: record_type } if id.present?
      end

      def ids_hash(ids, record_type)
        return ids.map { |id| id_hash(id, record_type) } if ids.respond_to? :map
        id_hash(ids, record_type) # ids variable is just a single id here
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
          serializer_class = @relationships_to_serialize[item][:serializer].to_s.constantize
          relationship_type = @relationships_to_serialize[item][:relationship_type]
          included_objects = record.send(object_method_name)
          next if included_objects.blank?
          included_objects = [included_objects] unless relationship_type == :has_many
          serializer = serializer_class.new
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
