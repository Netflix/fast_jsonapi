require 'fast_jsonapi'
require 'rspec-benchmark'
require 'multi_json'
require 'byebug'
require 'active_model_serializers'

Dir[File.dirname(__FILE__) + '/shared/contexts/*.rb'].each {|file| require file }

RSpec.configure do |config|
  config.include RSpec::Benchmark::Matchers
end

ActiveModel::Serializer.config.adapter = :json_api
ActiveModel::Serializer.config.key_transform = :underscore
ActiveModelSerializers.logger = ActiveSupport::TaggedLogging.new(ActiveSupport::Logger.new('/dev/null'))
