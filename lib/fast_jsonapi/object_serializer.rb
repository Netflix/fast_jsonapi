require 'active_support/core_ext/object'
require 'active_support/concern'
require 'active_support/inflector'
require 'oj'
require 'multi_json'
require 'fast_jsonapi/serialization_core'

begin
  require 'skylight'
  SKYLIGHT_ENABLED = true
rescue LoadError
  SKYLIGHT_ENABLED = false
end

module FastJsonapi
  module ObjectSerializer
    extend ActiveSupport::Concern
    include SerializationCore

    included do
      # Skylight integration
      # To remove Skylight
      # Remove the included do block
      # Remove the Gemfile entry
      if SKYLIGHT_ENABLED
        include Skylight::Helpers

        instrument_method :serializable_hash
        instrument_method :to_json
      end

      # Set record_type based on the name of the serializer class
      set_type default_record_type if default_record_type
    end

    def initialize(resource, options = {})
      if options.present?
        @meta_tags = options[:meta]
        @includes = options[:include].delete_if(&:blank?) if options[:include].present?
        self.class.has_permitted_includes(@includes) if @includes.present?
        @known_included_objects = {} # keep track of inc objects that have already been serialized
      end
      # @records if enumerables like Array, ActiveRecord::Relation but if Struct just make it a @record
      if resource.respond_to?(:each) && !resource.respond_to?(:each_pair)
        @records = resource
      else
        @record = resource
      end
    end

    def serializable_hash
      serializable_hash = { data: nil }
      serializable_hash[:meta] = @meta_tags if @meta_tags.present?
      return hash_for_one_record(serializable_hash) if @record
      return hash_for_multiple_records(serializable_hash) if @records
      serializable_hash
    end

    def hash_for_one_record(serializable_hash)
      serializable_hash[:data] = self.class.record_hash(@record)
      serializable_hash[:included] = self.class.get_included_records(@record, @includes, @known_included_objects) if @includes.present?
      serializable_hash
    end

    def hash_for_multiple_records(serializable_hash)
      data = []
      included = []
      @records.each do |record|
        data << self.class.record_hash(record)
        included.concat self.class.get_included_records(record, @includes, @known_included_objects) if @includes.present?
      end
      serializable_hash[:data] = data
      serializable_hash[:included] = included if @includes.present?
      serializable_hash
    end

    def serialized_json
      self.class.to_json(serializable_hash)
    end

    class_methods do
      def use_hyphen
        @hyphenated = true
      end

      def set_type(type_name)
        self.record_type = type_name
        if @hyphenated
          self.record_type = type_name.to_s.dasherize.to_sym
        end
      end

      def default_record_type
        if self.name.end_with?('Serializer')
          class_name = self.name.demodulize
          range_end = class_name.rindex('Serializer')
          class_name[0...range_end].underscore.to_sym
        end
      end

      def cache_options(cache_options)
        self.cached = cache_options[:enabled] || false
        self.cache_length = cache_options[:cache_length] || 5.minutes
      end

      def attributes(*attributes_list)
        attributes_list = attributes_list.first if attributes_list.first.class.is_a?(Array)
        self.attributes_to_serialize = {} if self.attributes_to_serialize.nil?
        attributes_list.each do |attr_name|
          method_name = attr_name
          key = method_name
          if @hyphenated
            key = attr_name.to_s.dasherize.to_sym
          end
          attributes_to_serialize[key] = method_name
        end
      end

      def add_relationship(name, relationship)
        self.relationships_to_serialize = {} if relationships_to_serialize.nil?
        self.cachable_relationships_to_serialize = {} if cachable_relationships_to_serialize.nil?
        self.uncachable_relationships_to_serialize = {} if uncachable_relationships_to_serialize.nil?

        if !relationship[:cached]
          self.uncachable_relationships_to_serialize[name] = relationship
        else
          self.cachable_relationships_to_serialize[name] = relationship
        end
        self.relationships_to_serialize[name] = relationship
     end

      def has_many(relationship_name, options = {})
        singular_name = relationship_name.to_s.singularize
        record_type = options[:record_type] || singular_name.to_sym
        name = relationship_name.to_sym
        key = options[:key] || name
        if @hyphenated
          key = options[:key] || relationship_name.to_s.dasherize.to_sym
          record_type = options[:record_type] || singular_name.to_s.dasherize.to_sym
        end
        serializer_key = options[:serializer] || record_type
        relationship = {
          key: key,
          name: name,
          id_method_name: options[:id_method_name] || (singular_name + '_ids').to_sym,
          record_type: record_type,
          object_method_name: options[:object_method_name] || name,
          serializer: compute_serializer_name(serializer_key),
          relationship_type: :has_many,
          cached: options[:cached] || false
        }
        add_relationship(name, relationship)
      end

      def belongs_to(relationship_name, options = {})
        name = relationship_name.to_sym
        key = options[:key] || name
        record_type = options[:record_type] || name
        serializer_key = options[:serializer] || record_type
        if @hyphenated
          key = options[:key] || relationship_name.to_s.dasherize.to_sym
          record_type = options[:record_type] || relationship_name.to_s.dasherize.to_sym
        end
        add_relationship(name, {
          key: key,
          name: name,
          id_method_name: options[:id_method_name] || (relationship_name.to_s + '_id').to_sym,
          record_type: record_type,
          object_method_name: options[:object_method_name] || name,
          serializer: compute_serializer_name(serializer_key),
          relationship_type: :belongs_to,
          cached: options[:cached] || true
        })
      end

      def has_one(relationship_name, options = {})
        name = relationship_name.to_sym
        key = options[:key] || name
        record_type = options[:record_type] || name
        serializer_key = options[:serializer] || record_type
        if @hyphenated
          key = options[:key] || relationship_name.to_s.dasherize.to_sym
          record_type = options[:record_type] || relationship_name.to_s.dasherize.to_sym
        end
        add_relationship(name, {
          key: key,
          name: name,
          id_method_name: options[:id_method_name] || (relationship_name.to_s + '_id').to_sym,
          record_type: record_type,
          object_method_name: options[:object_method_name] || name,
          serializer: compute_serializer_name(serializer_key),
          relationship_type: :has_one,
          cached: options[:cached] || false
        })
      end

      def compute_serializer_name(serializer_key)
        namespace = self.name.gsub(/()?\w+Serializer$/, '')
        serializer_name = serializer_key.to_s.classify + 'Serializer'
        return (namespace + serializer_name).to_sym if namespace.present?
        (serializer_key.to_s.classify + 'Serializer').to_sym
      end
    end
  end
end
