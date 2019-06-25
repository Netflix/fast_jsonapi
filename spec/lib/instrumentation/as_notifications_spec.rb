# frozen_string_literal: true

require 'spec_helper'

describe FastJsonapi::ObjectSerializer do
  include_context 'movie class'

  context 'instrument' do
    before(:all) do
      require 'fast_jsonapi/instrumentation'
    end

    after(:all) do
      %i[serialized_json serializable_hash].each do |m|
        alias_command = "alias_method :#{m}, :#{m}_without_instrumentation"
        FastJsonapi::ObjectSerializer.class_eval(alias_command)

        remove_command = "remove_method :#{m}_without_instrumentation"
        FastJsonapi::ObjectSerializer.class_eval(remove_command)
      end
    end

    before(:each) do
      options = {}
      options[:meta] = { total: 2 }
      options[:include] = [:actors]

      @serializer = MovieSerializer.new([movie, movie], options)
    end

    context 'serializable_hash' do
      it 'should send notifications' do
        events = []

        ActiveSupport::Notifications.subscribe(FastJsonapi::ObjectSerializer::SERIALIZABLE_HASH_NOTIFICATION) do |*args|
          events << ActiveSupport::Notifications::Event.new(*args)
        end

        serialized_hash = @serializer.serializable_hash

        expect(events.length).to eq(1)

        event = events.first

        expect(event.duration).to be > 0
        expect(event.payload).to eq(name: 'MovieSerializer')
        expect(event.name).to eq(FastJsonapi::ObjectSerializer::SERIALIZABLE_HASH_NOTIFICATION)

        expect(serialized_hash.key?(:data)).to eq(true)
        expect(serialized_hash.key?(:meta)).to eq(true)
        expect(serialized_hash.key?(:included)).to eq(true)
      end
    end

    context 'serialized_json' do
      it 'should send notifications' do
        events = []

        ActiveSupport::Notifications.subscribe(FastJsonapi::ObjectSerializer::SERIALIZED_JSON_NOTIFICATION) do |*args|
          events << ActiveSupport::Notifications::Event.new(*args)
        end

        json = @serializer.serialized_json

        expect(events.length).to eq(1)

        event = events.first

        expect(event.duration).to be > 0
        expect(event.payload).to eq(name: 'MovieSerializer')
        expect(event.name).to eq(FastJsonapi::ObjectSerializer::SERIALIZED_JSON_NOTIFICATION)

        expect(json.length).to be > 50
      end
    end
  end
end
