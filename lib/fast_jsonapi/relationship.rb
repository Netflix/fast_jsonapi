module FastJsonapi
  class Relationship
    attr_reader :key, :name, :id_method_name, :record_type, :object_method_name, :object_block, :serializer, :relationship_type, :cached, :polymorphic, :conditional_proc, :transform_method, :links, :lazy_load_data

    def initialize(
      key:,
      name:,
      id_method_name:,
      record_type:,
      object_method_name:,
      object_block:,
      serializer:,
      relationship_type:,
      cached: false,
      polymorphic:,
      conditional_proc:,
      transform_method:,
      links:,
      lazy_load_data: false
    )
      @key = key
      @name = name
      @id_method_name = id_method_name
      @record_type = record_type
      @object_method_name = object_method_name
      @object_block = object_block
      @serializer = serializer
      @relationship_type = relationship_type
      @cached = cached
      @polymorphic = polymorphic
      @conditional_proc = conditional_proc
      @transform_method = transform_method
      @links = links || {}
      @lazy_load_data = lazy_load_data
    end

    def serialize(record, serialization_params, output_hash)
      return unless include_relationship?(record, serialization_params)

      empty_case = relationship_type == :has_many ? [] : nil
      output_hash[key] = {}

      unless lazy_load_data
        output_hash[key] = ids_hash_from_record_and_relationship(record, serialization_params) || empty_case
      end

      add_links_hash(record, serialization_params, output_hash) if links.present?
    end

    def fetch_associated_object(record, params)
      return object_block.call(record, params) if object_block

      record.public_send(object_method_name)
    end

    def include_relationship?(record, serialization_params)
      if conditional_proc.present?
        conditional_proc.call(record, serialization_params)
      else
        true
      end
    end

    private

    def ids_hash_from_record_and_relationship(record, params = {})
      return ids_hash(fetch_id(record, params)) unless polymorphic
      return unless (associated_object = fetch_associated_object(record, params))
      return associated_object.map { |object| id_hash object.id } if associated_object.respond_to? :map

      id_hash associated_object.id
    end

    def ids_hash(ids)
      return ids.map { |id| id_hash id } if ids.respond_to? :map

      id_hash ids # ids variable is just a single id here
    end

    def id_hash(id, default_return = false)
      if id.present?
        { id: id }
      else
        default_return ? { id: nil } : nil
      end
    end

    def fetch_id(record, params)
      if object_block.present?
        object = object_block.call(record, params)
        return object.map { |item| item.public_send(id_method_name) } if object.respond_to? :map
        return object.try(id_method_name)
      end

      record.public_send(id_method_name)
    end

    def add_links_hash(record, params, output_hash)
      # TODO: figure out how to handle links
      return unless output_hash[key].is_a? Hash

      output_hash[key][:links] = links.each_with_object({}) do |(key, method), hash|
        Link.new(key: key, method: method).serialize(record, params, hash)
      end
    end

    def run_key_transform(input)
      if transform_method.present?
        input.to_s.public_send(*transform_method).to_sym
      else
        input.to_sym
      end
    end
  end
end
