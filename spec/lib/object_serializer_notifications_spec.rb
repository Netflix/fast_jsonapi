require 'spec_helper'

describe FastJsonapi::ObjectSerializer do
  include_context 'movie class'

  context 'instrument' do
    it 'serializable_hash' do
      options = {}
      options[:meta] = { total: 2 }
      options[:include] = [:actors]

      serializer = MovieSerializer.new([movie, movie], options)
      allow(serializer).to receive(:instrumentation_enabled?).and_return(true)

      events = []

      ActiveSupport::Notifications.subscribe(FastJsonapi::ObjectSerializer::SERIALIZE_HASH_NOTIFICATION) do |*args|
        events << ActiveSupport::Notifications::Event.new(*args)
      end

      serialized_hash = serializer.serializable_hash

      event = events.first

      expect(event.duration).to be > 0
      expect(event.payload).to eq({ name: 'MovieSerializer' })
      expect(event.name).to eq(FastJsonapi::ObjectSerializer::SERIALIZE_HASH_NOTIFICATION)

      expect(serialized_hash.key?(:data)).to eq(true)
      expect(serialized_hash.key?(:meta)).to eq(true)
      expect(serialized_hash.key?(:included)).to eq(true)
    end

    it 'to_json' do
      options = {}
      options[:meta] = { total: 2 }
      options[:include] = [:actors]

      serializer = MovieSerializer.new([movie, movie], options)
      allow(serializer).to receive(:instrumentation_enabled?).and_return(true)

      events = []

      ActiveSupport::Notifications.subscribe(FastJsonapi::ObjectSerializer::TO_JSON_HASH_NOTIFICATION) do |*args|
        events << ActiveSupport::Notifications::Event.new(*args)
      end

      json = serializer.to_json

      event = events.first

      expect(event.duration).to be > 0
      expect(event.payload).to eq({ name: 'MovieSerializer' })
      expect(event.name).to eq(FastJsonapi::ObjectSerializer::TO_JSON_HASH_NOTIFICATION)

      expect(json.length).to be > 50
    end
  end
end
