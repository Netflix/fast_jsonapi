require 'active_support/notifications'

module FastJsonapi
  module ObjectSerializer

    alias_method :serialized_json_without_instrumentation, :serialized_json

    def serialized_json
      ActiveSupport::Notifications.instrument(SERIALIZED_JSON_NOTIFICATION, { name: self.class.name }) do
        serialized_json_without_instrumentation
      end
    end

  end
end
