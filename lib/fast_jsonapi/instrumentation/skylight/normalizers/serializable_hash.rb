require 'skylight'
require 'fast_jsonapi/instrumentation/serializable_hash'

module FastJsonapi
  module Instrumentation
    module Skylight
      module Normalizers
        class SerializableHash < Skylight::Normalizers::Normalizer

          register FastJsonapi::ObjectSerializer::SERIALIZABLE_HASH_NOTIFICATION

          CAT = "view.#{FastJsonapi::ObjectSerializer::SERIALIZABLE_HASH_NOTIFICATION}".freeze

          def normalize(trace, name, payload)
            [ CAT, payload[:name], nil ]
          end

        end
      end
    end
  end
end
