# frozen_string_literal: true

require 'logger'

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

    def self.logger(device=nil)
      return @logger = Logger.new(device) if device
      @logger ||= Logger.new(IO::NULL)
    end

    # Encoder-compatible with default MultiJSON adapters and defaults
    def self.to_json_method
      encode_method = String.new(%(def _fast_to_json(object)\n ))
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

    def self.to_json(object)
      _fast_to_json(object)
    rescue NameError
      define_to_json(FastJsonapi::MultiToJson)
      _fast_to_json(object)
    end

    def self.define_to_json(receiver)
      cl = caller_locations[0]
      method_body = to_json_method
      logger.debug { "Defining #{receiver}._fast_to_json as #{method_body.inspect}" }
      receiver.instance_eval method_body, cl.absolute_path, cl.lineno
    end

    def self.reset_to_json!
      undef :_fast_to_json if method_defined?(:_fast_to_json)
      logger.debug { "Undefining #{receiver}._fast_to_json" }
    end
  end
end
