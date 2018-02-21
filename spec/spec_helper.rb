require 'fast_jsonapi'
require 'rspec-benchmark'
require 'byebug'
require 'active_model_serializers'
require 'jsonapi/serializable'
require 'jsonapi-serializers'
require 'oj'
require 'oj_mimic_json'

Dir[File.dirname(__FILE__) + '/shared/contexts/*.rb'].each {|file| require file }

RSpec.configure do |config|
  config.include RSpec::Benchmark::Matchers
  if ENV['TRAVIS'] == 'true' || ENV['TRAVIS'] == true
    config.filter_run_excluding performance: true
  end
end

Oj.optimize_rails
ActiveModel::Serializer.config.adapter = :json_api
ActiveModel::Serializer.config.key_transform = :unaltered
# ActiveModelSerializers.logger = ActiveSupport::TaggedLogging.new(ActiveSupport::Logger.new('/dev/null'))
ActiveSupport::Notifications.unsubscribe(ActiveModelSerializers::Logging::RENDER_EVENT)
