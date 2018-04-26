# frozen_string_literal: true

require 'active_support/core_ext/object'
require 'active_support/concern'
require 'active_support/inflector'
require 'fast_jsonapi/serialization_core'

module FastJsonapi
  module ObjectSerializer
    extend ActiveSupport::Concern
    include SerializationCore

    SERIALIZABLE_HASH_NOTIFICATION = 'render.fast_jsonapi.serializable_hash'
    SERIALIZED_JSON_NOTIFICATION = 'render.fast_jsonapi.serialized_json'

    included do
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
    alias_method :to_hash, :serializable_hash

    def hash_for_one_record
      serializable_hash = { data: nil }
      serializable_hash[:meta] = @meta if @meta.present?
      serializable_hash[:links] = @links if @links.present?

      return serializable_hash unless @resource

      serializable_hash[:data] = self.class.record_hash(@resource)
      serializable_hash[:included] = self.class.get_included_records(@resource, @includes, @known_included_objects) if @includes.present?
      serializable_hash
    end

    def hash_for_collection
      serializable_hash = {}

      data = []
      included = []
      @resource.each do |record|
        data << self.class.record_hash(record)
        included.concat self.class.get_included_records(record, @includes, @known_included_objects) if @includes.present?
      end

      serializable_hash[:data] = data
      serializable_hash[:included] = included if @includes.present?
      serializable_hash[:meta] = @meta if @meta.present?
      serializable_hash[:links] = @links if @links.present?
      serializable_hash
    end

    def serialized_json
      self.class.to_json(serializable_hash)
    end

    private

    def process_options(options)
      return if options.blank?

      @known_included_objects = {}
      @meta = options[:meta]
      @links = options[:links]

      if options[:include].present?
        @includes = options[:include].delete_if(&:blank?).map(&:to_sym)
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
      def reflected_record_type
        return @reflected_record_type if defined?(@reflected_record_type)

        @reflected_record_type ||= begin
          if self.name.end_with?('Serializer')
            self.name.split('::').last.chomp('Serializer').underscore.to_sym
          end
        end
      end

      def set_key_transform(transform_name)
        mapping = {
          camel: :camelize,
          camel_lower: [:camelize, :lower],
          dash: :dasherize,
          underscore: :underscore
        }
        self.transform_method = mapping[transform_name.to_sym]
      end

      def run_key_transform(input)
        if self.transform_method.present?
          input.to_s.send(*@transform_method).to_sym
        else
          input.to_sym
        end
      end

      def use_hyphen
        warn('DEPRECATION WARNING: use_hyphen is deprecated and will be removed from fast_jsonapi 2.0 use (set_key_transform :dash) instead')
        set_key_transform :dash
      end

      def set_type(type_name)
        self.record_type = run_key_transform(type_name)
      end

      def set_id(id_name)
        self.record_id = id_name
      end

      def cache_options(cache_options)
        self.cached = cache_options[:enabled] || false
        self.cache_length = cache_options[:cache_length] || 5.minutes
        self.race_condition_ttl = cache_options[:race_condition_ttl] || 5.seconds
      end

      def attributes(*attributes_list, &block)
        attributes_list = attributes_list.first if attributes_list.first.class.is_a?(Array)
        self.attributes_to_serialize = {} if self.attributes_to_serialize.nil?
        attributes_list.each do |attr_name|
          method_name = attr_name
          key = run_key_transform(method_name)
          attributes_to_serialize[key] = block || method_name
        end
      end

      alias_method :attribute, :attributes

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
        name = relationship_name.to_sym
        hash = create_relationship_hash(relationship_name, :has_many, options)
        add_relationship(name, hash)
      end

      def belongs_to(relationship_name, options = {})
        name = relationship_name.to_sym
        hash = create_relationship_hash(relationship_name, :belongs_to, options)
        add_relationship(name, hash)
      end

      def has_one(relationship_name, options = {})
        name = relationship_name.to_sym
        hash = create_relationship_hash(relationship_name, :has_one, options)
        add_relationship(name, hash)
      end

      def create_relationship_hash(base_key, relationship_type, options)
        name = base_key.to_sym
        if relationship_type == :has_many
          base_serialization_key = base_key.to_s.singularize
          base_key_sym = base_serialization_key.to_sym
          id_postfix = '_ids'
        else
          base_serialization_key = base_key
          base_key_sym = name
          id_postfix = '_id'
        end
        {
          key: options[:key] || run_key_transform(base_key),
          name: name,
          id_method_name: options[:id_method_name] || "#{base_serialization_key}#{id_postfix}".to_sym,
          record_type: options[:record_type] || run_key_transform(base_key_sym),
          object_method_name: options[:object_method_name] || name,
          serializer: compute_serializer_name(options[:serializer] || base_key_sym),
          relationship_type: relationship_type,
          cached: options[:cached] || false,
          polymorphic: fetch_polymorphic_option(options)
        }
      end

      def compute_serializer_name(serializer_key)
        namespace = self.name.gsub(/()?\w+Serializer$/, '')
        serializer_name = serializer_key.to_s.classify + 'Serializer'
        return (namespace + serializer_name).to_sym if namespace.present?
        (serializer_key.to_s.classify + 'Serializer').to_sym
      end

      def fetch_polymorphic_option(options)
        option = options[:polymorphic]
        return false unless option.present?
        return option if option.respond_to? :keys
        {}
      end
    end
  end
end
