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
      if include_relationship?(record, serialization_params)
        empty_case = relationship_type == :has_many ? [] : nil

        output_hash[key] = {}
        unless lazy_load_data
          output_hash[key][:data] = ids_hash_from_record_and_relationship(record, serialization_params) || empty_case
        end
        add_links_hash(record, serialization_params, output_hash) if links.present?
      end
    end

    def fetch_associated_object(record, params)
      return object_block.call(record, params) unless object_block.nil?
      record.send(object_method_name)
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
      return ids_hash(
        fetch_id(record, params)
      ) unless polymorphic

      return unless associated_object = fetch_associated_object(record, params)

      return associated_object.map do |object|
        id_hash_from_record object, polymorphic
      end if associated_object.respond_to? :map

      id_hash_from_record associated_object, polymorphic
    end

    def id_hash_from_record(record, record_types)
      # memoize the record type within the record_types dictionary, then assigning to record_type:
      associated_record_type = record_types[record.class] ||= run_key_transform(record.class.name.demodulize.underscore)
      id_hash(record.id, associated_record_type)
    end

    def ids_hash(ids)
      return ids.map { |id| id_hash(id, record_type) } if ids.respond_to? :map
      id_hash(ids, record_type) # ids variable is just a single id here
    end

    def id_hash(id, record_type, default_return=false)
      if id.present?
        { id: id.to_s, type: record_type }
      else
        default_return ? { id: nil, type: record_type } : nil
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
      output_hash[key][:links] = links.each_with_object({}) do |(key, method), hash|
        Link.new(key: key, method: method).serialize(record, params, hash)\
      end
    end

    def run_key_transform(input)
      if self.transform_method.present?
        input.to_s.send(*self.transform_method).to_sym
      else
        input.to_sym
      end
    end
  end
end
