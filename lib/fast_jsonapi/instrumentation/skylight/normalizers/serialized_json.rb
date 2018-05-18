require 'fast_jsonapi/instrumentation/skylight/normalizers/base'
require 'fast_jsonapi/instrumentation/serializable_hash'

module FastJsonapi
  module Instrumentation
    module Skylight
      module Normalizers
        class SerializedJson < SKYLIGHT_NORMALIZER_BASE_CLASS

          register FastJsonapi::ObjectSerializer::SERIALIZED_JSON_NOTIFICATION

          CAT = "view.#{FastJsonapi::ObjectSerializer::SERIALIZED_JSON_NOTIFICATION}".freeze

          def normalize(trace, name, payload)
            [ CAT, payload[:name], nil ]
          end

        end
      end
    end
  end
end
