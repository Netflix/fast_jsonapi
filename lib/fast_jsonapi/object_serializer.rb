# frozen_string_literal: true

require 'active_support/time'
require 'active_support/json'
require 'active_support/concern'
require 'active_support/inflector'
require 'active_support/core_ext/numeric/time'
require 'fast_jsonapi/attribute'
require 'fast_jsonapi/relationship'
require 'fast_jsonapi/link'
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
      return hash_for_collection if is_collection?(@resource, @is_collection)

      hash_for_one_record
    end
    alias_method :to_hash, :serializable_hash

    def hash_for_one_record
      serializable_hash = { data: nil }
      serializable_hash[:meta] = @meta if @meta.present?
      serializable_hash[:links] = @links if @links.present?

      return serializable_hash unless @resource

      serializable_hash[:data] = self.class.record_hash(@resource, @fieldsets[self.class.record_type.to_sym], @params)
      serializable_hash[:included] = self.class.get_included_records(@resource, @includes, @known_included_objects, @fieldsets, @params) if @includes.present?
      serializable_hash
    end

    def hash_for_collection
      serializable_hash = {}

      data = []
      included = []
      fieldset = @fieldsets[self.class.record_type.to_sym]
      @resource.each do |record|
        data << self.class.record_hash(record, fieldset, @params)
        included.concat self.class.get_included_records(record, @includes, @known_included_objects, @fieldsets, @params) if @includes.present?
      end

      serializable_hash[:data] = data
      serializable_hash[:included] = included if @includes.present?
      serializable_hash[:meta] = @meta if @meta.present?
      serializable_hash[:links] = @links if @links.present?
      serializable_hash
    end

    def serialized_json
      ActiveSupport::JSON.encode(serializable_hash)
    end

    private

    def process_options(options)
      @fieldsets = deep_symbolize(options[:fields].presence || {})
      @params = {}

      return if options.blank?

      @known_included_objects = {}
      @meta = options[:meta]
      @links = options[:links]
      @is_collection = options[:is_collection]
      @params = options[:params] || {}
      raise ArgumentError.new("`params` option passed to serializer must be a hash") unless @params.is_a?(Hash)

      if options[:include].present?
        @includes = options[:include].delete_if(&:blank?).map(&:to_sym)
        self.class.validate_includes!(@includes)
      end
    end

    def deep_symbolize(collection)
      if collection.is_a? Hash
        Hash[collection.map do |k, v|
          [k.to_sym, deep_symbolize(v)]
        end]
      elsif collection.is_a? Array
        collection.map { |i| deep_symbolize(i) }
      else
        collection.to_sym
      end
    end

    def is_collection?(resource, force_is_collection = nil)
      return force_is_collection unless force_is_collection.nil?

      resource.respond_to?(:size) && !resource.respond_to?(:each_pair)
    end

    class_methods do

      def inherited(subclass)
        super(subclass)
        subclass.attributes_to_serialize = attributes_to_serialize.dup if attributes_to_serialize.present?
        subclass.relationships_to_serialize = relationships_to_serialize.dup if relationships_to_serialize.present?
        subclass.cachable_relationships_to_serialize = cachable_relationships_to_serialize.dup if cachable_relationships_to_serialize.present?
        subclass.uncachable_relationships_to_serialize = uncachable_relationships_to_serialize.dup if uncachable_relationships_to_serialize.present?
        subclass.transform_method = transform_method
        subclass.cache_length = cache_length
        subclass.race_condition_ttl = race_condition_ttl
        subclass.data_links = data_links.dup if data_links.present?
        subclass.cached = cached
        subclass.set_type(subclass.reflected_record_type) if subclass.reflected_record_type
        subclass.meta_to_serialize = meta_to_serialize
      end

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

        # ensure that the record type is correctly transformed
        if record_type
          set_type(record_type)
        elsif reflected_record_type
          set_type(reflected_record_type)
        end
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

      def set_id(id_name = nil, &block)
        self.record_id = block || id_name
      end

      def cache_options(cache_options)
        self.cached = cache_options[:enabled] || false
        self.cache_length = cache_options[:cache_length] || 5.minutes
        self.race_condition_ttl = cache_options[:race_condition_ttl] || 5.seconds
      end

      def attributes(*attributes_list, &block)
        attributes_list = attributes_list.first if attributes_list.first.class.is_a?(Array)
        options = attributes_list.last.is_a?(Hash) ? attributes_list.pop : {}
        self.attributes_to_serialize = {} if self.attributes_to_serialize.nil?

        attributes_list.each do |attr_name|
          method_name = attr_name
          key = run_key_transform(method_name)
          attributes_to_serialize[key] = Attribute.new(
            key: key,
            method: block || method_name,
            options: options
          )
        end
      end

      alias_method :attribute, :attributes

      def add_relationship(relationship)
        self.relationships_to_serialize = {} if relationships_to_serialize.nil?
        self.cachable_relationships_to_serialize = {} if cachable_relationships_to_serialize.nil?
        self.uncachable_relationships_to_serialize = {} if uncachable_relationships_to_serialize.nil?

        if !relationship.cached
          self.uncachable_relationships_to_serialize[relationship.name] = relationship
        else
          self.cachable_relationships_to_serialize[relationship.name] = relationship
        end
        self.relationships_to_serialize[relationship.name] = relationship
      end

      def has_many(relationship_name, options = {}, &block)
        relationship = create_relationship(relationship_name, :has_many, options, block)
        add_relationship(relationship)
      end

      def has_one(relationship_name, options = {}, &block)
        relationship = create_relationship(relationship_name, :has_one, options, block)
        add_relationship(relationship)
      end

      def belongs_to(relationship_name, options = {}, &block)
        relationship = create_relationship(relationship_name, :belongs_to, options, block)
        add_relationship(relationship)
      end

      def meta(&block)
        self.meta_to_serialize = block
      end

      def create_relationship(base_key, relationship_type, options, block)
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
        Relationship.new(
          key: options[:key] || run_key_transform(base_key),
          name: name,
          id_method_name: compute_id_method_name(
            options[:id_method_name],
            "#{base_serialization_key}#{id_postfix}".to_sym,
            block
          ),
          record_type: options[:record_type] || run_key_transform(base_key_sym),
          object_method_name: options[:object_method_name] || name,
          object_block: block,
          serializer: compute_serializer_name(options[:serializer] || base_key_sym),
          relationship_type: relationship_type,
          cached: options[:cached],
          polymorphic: fetch_polymorphic_option(options),
          conditional_proc: options[:if],
          transform_method: @transform_method,
          links: options[:links],
          lazy_load_data: options[:lazy_load_data]
        )
      end

      def compute_id_method_name(custom_id_method_name, id_method_name_from_relationship, block)
        if block.present?
          custom_id_method_name || :id
        else
          custom_id_method_name || id_method_name_from_relationship
        end
      end

      def compute_serializer_name(serializer_key)
        return serializer_key unless serializer_key.is_a? Symbol
        namespace = self.name.gsub(/()?\w+Serializer$/, '')
        serializer_name = serializer_key.to_s.classify + 'Serializer'
        (namespace + serializer_name).to_sym
      end

      def fetch_polymorphic_option(options)
        option = options[:polymorphic]
        return false unless option.present?
        return option if option.respond_to? :keys
        {}
      end

      def link(link_name, link_method_name = nil, &block)
        self.data_links = {} if self.data_links.nil?
        link_method_name = link_name if link_method_name.nil?
        key = run_key_transform(link_name)

        self.data_links[key] = Link.new(
          key: key,
          method: block || link_method_name
        )
      end

      def validate_includes!(includes)
        return if includes.blank?

        includes.detect do |include_item|
          klass = self
          parse_include_item(include_item).each do |parsed_include|
            relationships_to_serialize = klass.relationships_to_serialize || {}
            relationship_to_include = relationships_to_serialize[parsed_include]
            raise ArgumentError, "#{parsed_include} is not specified as a relationship on #{klass.name}" unless relationship_to_include
            klass = relationship_to_include.serializer.to_s.constantize unless relationship_to_include.polymorphic.is_a?(Hash)
          end
        end
      end
    end
  end
end
