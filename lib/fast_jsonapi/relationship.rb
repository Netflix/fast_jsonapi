module FastJsonapi
  class Relationship
    attr_reader :key, :name, :id_method_name, :record_type, :object_method_name, :object_block, :serializer, :relationship_type, :cached, :polymorphic, :conditional_proc

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
      conditional_proc:
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
    end

    def serialize(record, serialization_params, output_hash)
      if include_relationship?(record, serialization_params)
        empty_case = relationship_type == :has_many ? [] : nil
        output_hash[key] = {
          data: ids_hash_from_record_and_relationship(record, serialization_params) || empty_case
        }
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
      associated_record_type = record_types[record.class] ||= record.class.name.underscore.to_sym
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
      unless object_block.nil?
        object = object_block.call(record, params)

        return object.map(&:id) if object.respond_to? :map
        return object.try(:id)
      end

      record.public_send(id_method_name)
    end
  end
end