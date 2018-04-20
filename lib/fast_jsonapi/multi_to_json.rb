# frozen_string_literal: true

# Usage:
#   class Movie
#     def to_json(payload)
#       FastJsonapi::MultiToJson.to_json(payload)
#     end
#   end
module FastJsonapi
  module MultiToJson
    # Result object pattern is from https://johnnunemaker.com/resilience-in-ruby/
    # e.g. https://github.com/github/github-ds/blob/fbda5389711edfb4c10b6c6bad19311dfcb1bac1/lib/github/result.rb
    class Result
      def initialize(*rescued_exceptions)
        @rescued_exceptions = if rescued_exceptions.empty?
          [StandardError]
        else
          rescued_exceptions
        end

        @value = yield
        @error = nil
      rescue *rescued_exceptions => e
        @error = e
      end

      def ok?
        @error.nil?
      end

      def value!
        if ok?
          @value
        else
          raise @error
        end
      end

      def rescue
        return self if ok?

        Result.new(*@rescued_exceptions) { yield(@error) }
      end
    end

    # Encoder-compatible with default MultiJSON adapters and defaults
    def self.to_json_method
      encode_method = String.new(%(def self.to_json(object)\n ))
      encode_method << Result.new(LoadError) {
        require 'oj'
        %(::Oj.dump(object, mode: :compat, time_format: :ruby, use_to_json: true))
      }.rescue {
        require 'yajl'
        %(::Yajl::Encoder.encode(object))
      }.rescue {
        require 'jrjackson' unless defined?(::JrJackson)
        %(::JrJackson::Json.dump(object))
      }.rescue {
        require 'json'
        %(JSON.fast_generate(object, create_additions: false, quirks_mode: true))
      }.rescue {
        require 'gson'
        %(::Gson::Encoder.new({}).encode(object))
      }.rescue {
        require 'active_support/json/encoding'
        %(::ActiveSupport::JSON.encode(object))
      }.rescue {
        warn "No JSON encoder found. Falling back to `object.to_json`"
        %(object.to_json)
      }.value!
      encode_method << "\nend"
    end

    class_eval to_json_method,__FILE__, __LINE__
  end
end
