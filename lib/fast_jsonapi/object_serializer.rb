require 'active_support/core_ext/object'
require 'active_support/concern'
require 'active_support/inflector'
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
      set_type(reflected_record_type) if reflected_record_type
    end

    def initialize(resource, options = {})
      process_options(options)

      @resource = resource
    end

    def serializable_hash
      return hash_for_collection if is_collection?(@resource)

      hash_for_one_record
    end

    def hash_for_one_record
      serializable_hash = { data: nil }
      serializable_hash[:meta] = @meta if @meta.present?

      return serializable_hash unless @resource

      serializable_hash[:data] = self.record_hash
      serializable_hash[:included] = self.get_included_records(@includes, @known_included_objects) if @includes.present?
      serializable_hash
    end

    def hash_for_collection
      serializable_hash = {}

      data = []
      included = []
      @resource.each do |record|
        serializer = self.class.new(record)
        data << serializer.record_hash
        included.concat serializer.get_included_records(@includes, @known_included_objects) if @includes.present?
      end

      serializable_hash[:data] = data
      serializable_hash[:included] = included if @includes.present?
      serializable_hash[:meta] = @meta if @meta.present?
      serializable_hash
    end

    def serialized_json
      self.to_json(serializable_hash)
    end

    private

    def process_options(options)
      return if options.blank?

      @known_included_objects = {}
      @meta = options[:meta]

      if options[:include].present?
        @includes = options[:include].delete_if(&:blank?)
        validate_includes!(@includes)
      end
    end

    def validate_includes!(includes)
      return if includes.blank?

      existing_relationships = self.class.relationships_to_serialize.keys.to_set

      unless existing_relationships.superset?(includes.to_set)
        raise ArgumentError, "One of keys from #{includes} is not specified as a relationship on the serializer"
      end
    end

    def is_collection?(resource)
      resource.respond_to?(:each) && !resource.respond_to?(:each_pair)
    end

    class_methods do
      def use_hyphen
        @hyphenated = true
      end

      def set_type(type)
        return unless type

        type = type.to_s.underscore
        type = type.dasherize if @hyphenated

        self.record_type = type.to_sym
      end

      def reflected_record_type
        return @reflected_record_type if defined?(@reflected_record_type)

        @reflected_record_type ||= begin
          if self.name.end_with?('Serializer')
            self.name.split('::').last.chomp('Serializer').underscore.to_sym
          end
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
