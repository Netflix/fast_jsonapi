require 'spec_helper'

describe FastJsonapi::ObjectSerializer do
  include_context 'movie class'

  context 'instrument' do

    before(:each) do
      options = {}
      options[:meta] = { total: 2 }
      options[:include] = [:actors]

      @serializer = MovieSerializer.new([movie, movie], options)
    end

    context 'serializable_hash' do

      it 'should send notifications' do
        allow(@serializer).to receive(:instrumentation_enabled?).and_return(true)

        events = []

        ActiveSupport::Notifications.subscribe(FastJsonapi::ObjectSerializer::SERIALIZE_HASH_NOTIFICATION) do |*args|
          events << ActiveSupport::Notifications::Event.new(*args)
        end

        serialized_hash = @serializer.serializable_hash

        expect(events.length).to eq(1)

        event = events.first

        expect(event.duration).to be > 0
        expect(event.payload).to eq({ name: 'MovieSerializer' })
        expect(event.name).to eq(FastJsonapi::ObjectSerializer::SERIALIZE_HASH_NOTIFICATION)

        expect(serialized_hash.key?(:data)).to eq(true)
        expect(serialized_hash.key?(:meta)).to eq(true)
        expect(serialized_hash.key?(:included)).to eq(true)
      end

      it 'should send not notifications' do
        allow(@serializer).to receive(:instrumentation_enabled?).and_return(false)

        events = []

        ActiveSupport::Notifications.subscribe(FastJsonapi::ObjectSerializer::SERIALIZE_HASH_NOTIFICATION) do |*args|
          events << ActiveSupport::Notifications::Event.new(*args)
        end

        serialized_hash = @serializer.serializable_hash

        expect(events.length).to eq(0)

        expect(serialized_hash.key?(:data)).to eq(true)
        expect(serialized_hash.key?(:meta)).to eq(true)
        expect(serialized_hash.key?(:included)).to eq(true)
      end

    end

    context 'serialized_json' do

      it 'should send notifications' do
        allow(@serializer).to receive(:instrumentation_enabled?).and_return(true)

        events = []

        ActiveSupport::Notifications.subscribe(FastJsonapi::ObjectSerializer::SERIALIZED_JSON_NOTIFICATION) do |*args|
          events << ActiveSupport::Notifications::Event.new(*args)
        end

        json = @serializer.serialized_json

        expect(events.length).to eq(1)

        event = events.first

        expect(event.duration).to be > 0
        expect(event.payload).to eq({ name: 'MovieSerializer' })
        expect(event.name).to eq(FastJsonapi::ObjectSerializer::SERIALIZED_JSON_NOTIFICATION)

        expect(json.length).to be > 50
      end

      it 'should send not notifications' do
        allow(@serializer).to receive(:instrumentation_enabled?).and_return(false)

        events = []

        ActiveSupport::Notifications.subscribe(FastJsonapi::ObjectSerializer::SERIALIZED_JSON_NOTIFICATION) do |*args|
          events << ActiveSupport::Notifications::Event.new(*args)
        end

        json = @serializer.serialized_json

        expect(events.length).to eq(0)

        expect(json.length).to be > 50
      end

    end

    context 'to_json' do

      it 'should send notifications' do
        allow(@serializer).to receive(:instrumentation_enabled?).and_return(true)

        events = []

        ActiveSupport::Notifications.subscribe(FastJsonapi::ObjectSerializer::TO_JSON_NOTIFICATION) do |*args|
          events << ActiveSupport::Notifications::Event.new(*args)
        end

        json = @serializer.to_json

        expect(events.length).to eq(1)

        event = events.first

        expect(event.duration).to be > 0
        expect(event.payload).to eq({ name: 'MovieSerializer' })
        expect(event.name).to eq(FastJsonapi::ObjectSerializer::TO_JSON_NOTIFICATION)

        expect(json.length).to be > 50
      end

      it 'should send not notifications' do
        allow(@serializer).to receive(:instrumentation_enabled?).and_return(false)

        events = []

        ActiveSupport::Notifications.subscribe(FastJsonapi::ObjectSerializer::TO_JSON_NOTIFICATION) do |*args|
          events << ActiveSupport::Notifications::Event.new(*args)
        end

        json = @serializer.to_json

        expect(events.length).to eq(0)

        expect(json.length).to be > 50
      end

    end

  end

end
