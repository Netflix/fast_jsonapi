module FastJsonapi
  class Link
    attr_reader :key, :method

    def initialize(key:, method:)
      @key = key
      @method = method
    end

    def serialize(record, serialization_params, output_hash)
      output_hash[key] = if method.is_a?(Proc)
        method.arity == 1 ? method.call(record) : method.call(record, serialization_params)
      else
        record.public_send(method)
      end
    end
  end
end
