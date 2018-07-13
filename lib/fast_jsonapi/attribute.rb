module FastJsonapi
  class Attribute
    attr_reader :key, :method, :conditional_proc

    def initialize(key:, method:, options: {})
      @key = key
      @method = method
      @conditional_proc = options[:if]
    end

    def serialize(record, serialization_params, output_hash)
      if include_attribute?(record, serialization_params)
        output_hash[key] = if method.is_a?(Proc)
          method.arity.abs == 1 ? method.call(record) : method.call(record, serialization_params)
        else
          record.public_send(method)
        end
      end
    end

    def include_attribute?(record, serialization_params)
      if conditional_proc.present?
        conditional_proc.call(record, serialization_params)
      else
        true
      end
    end
  end
end
