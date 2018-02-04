require 'active_support/concern'

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
    end

    class_methods do
      def id_hash(id, record_type)
        return { id: id.to_s, type: record_type } if id.present?
      end

      def ids_hash(ids, record_type)
        return ids.map { |id| id_hash(id, record_type) } if ids.respond_to? :map
        id_hash(ids, record_type) # ids variable is just a single id here
      end

      def attributes_hash(record)
        attributes_hash = {}
        attributes_to_serialize.each do |key, method_name|
          attributes_hash[key] = record.send(method_name)
        end
        attributes_hash
      end

      def relationships_hash(record, relationships = nil)
        relationships_hash = {}
        relationships = relationships_to_serialize if relationships.nil?

        relationships.each do |_k, relationship|
          name = relationship[:key]
          id_method_name = relationship[:id_method_name]
          record_type = relationship[:record_type]
          empty_case = relationship[:relationship_type] == :has_many ? [] : nil
          relationships_hash[name] = {
            data: ids_hash(record.send(id_method_name), record_type) || empty_case
          }
        end
        relationships_hash
      end

      def record_hash(record)
        if cached
          record_hash = Rails.cache.fetch(record.cache_key, expires_in: cache_length) do
            record_hash = id_hash(record.id, record_type) || { id: nil, type: record_type }
            record_hash[:attributes] = attributes_hash(record) if attributes_to_serialize.present?
            record_hash[:relationships] = {}
            record_hash[:relationships] = relationships_hash(record, cachable_relationships_to_serialize) if cachable_relationships_to_serialize.present?
            record_hash
          end
          record_hash[:relationships] = record_hash[:relationships].merge(relationships_hash(record, uncachable_relationships_to_serialize)) if uncachable_relationships_to_serialize.present?
          record_hash
        else
          record_hash = id_hash(record.id, record_type) || { id: nil, type: record_type }
          record_hash[:attributes] = attributes_hash(record) if attributes_to_serialize.present?
          record_hash[:relationships] = relationships_hash(record) if relationships_to_serialize.present?
          record_hash
        end
      end

      def to_json(payload)
        MultiJson.dump(payload) if payload.present?
      end

      # includes handler

      def get_included_records(record, includes_list, known_included_objects)
        included_records = []
        includes_list.each do |item|
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
        included_records
      end
    end
  end
end
