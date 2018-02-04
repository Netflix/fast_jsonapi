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

    def record
      @resource
    end

    def id_hash(id, record_type)
      return { id: id.to_s, type: record_type } if id.present?
    end

    def ids_hash(ids, record_type)
      return ids.map { |id| id_hash(id, record_type) } if ids.respond_to? :map
      id_hash(ids, record_type) # ids variable is just a single id here
    end

    def attributes_hash
      self.class.attributes_to_serialize.each_with_object({}) do |(key, method_name), attr_hash|
        attr_hash[key] = respond_to?(method_name) ? public_send(method_name) : record.public_send(method_name)
      end
    end

    def relationships_hash(relationships = nil)
      relationships = self.class.relationships_to_serialize if relationships.nil?

      relationships.each_with_object({}) do |(_k, relationship), hash|
        name = relationship[:key]
        id_method_name = relationship[:id_method_name]
        record_type = relationship[:record_type]
        empty_case = relationship[:relationship_type] == :has_many ? [] : nil
        hash[name] = {
          data: ids_hash(record.public_send(id_method_name), record_type) || empty_case
        }
      end
    end

    def record_hash
      if self.class.cached
        record_hash = Rails.cache.fetch(record.cache_key, expires_in: self.class.cache_length) do
          temp_hash = id_hash(record.id, self.class.record_type) || { id: nil, type: self.class.record_type }
          temp_hash[:attributes] = attributes_hash if self.class.attributes_to_serialize.present?
          temp_hash[:relationships] = {}
          temp_hash[:relationships] = relationships_hash(self.class.cachable_relationships_to_serialize) if self.class.cachable_relationships_to_serialize.present?
          temp_hash
        end
        record_hash[:relationships] = record_hash[:relationships].merge(relationships_hash(self.class.uncachable_relationships_to_serialize)) if self.class.uncachable_relationships_to_serialize.present?
        record_hash
      else
        record_hash = id_hash(record.id, self.class.record_type) || { id: nil, type: self.class.record_type }
        record_hash[:attributes] = attributes_hash if self.class.attributes_to_serialize.present?
        record_hash[:relationships] = relationships_hash if self.class.relationships_to_serialize.present?
        record_hash
      end
    end

    def to_json(payload)
      MultiJson.dump(payload) if payload.present?
    end

    # includes handler

    def get_included_records(includes_list, known_included_objects)
      includes_list.each_with_object([]) do |item, included_records|
        object_method_name = self.class.relationships_to_serialize[item][:object_method_name]
        record_type = self.class.relationships_to_serialize[item][:record_type]
        serializer = self.class.relationships_to_serialize[item][:serializer].to_s.constantize
        relationship_type = self.class.relationships_to_serialize[item][:relationship_type]
        included_objects = record.send(object_method_name)
        next if included_objects.blank?
        included_objects = [included_objects] unless relationship_type == :has_many
        included_objects.each do |inc_obj|
          code = "#{record_type}_#{inc_obj.id}"
          next if known_included_objects.key?(code)
          known_included_objects[code] = inc_obj
          included_records << serializer.new(inc_obj).record_hash
        end
      end
    end
  end
end
