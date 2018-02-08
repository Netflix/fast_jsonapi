require 'spec_helper'

describe FastJsonapi::ObjectSerializer do
  include_context 'movie class'

  context 'when testing instance methods of object serializer' do
    it 'returns correct hash when serializable_hash is called' do
      options = {}
      options[:meta] = { total: 2 }
      options[:include] = [:actors]
      serializable_hash = MovieSerializer.new([movie, movie], options).serializable_hash

      expect(serializable_hash[:data].length).to eq 2
      expect(serializable_hash[:data][0][:relationships].length).to eq 3
      expect(serializable_hash[:data][0][:attributes].length).to eq 2

      expect(serializable_hash[:meta]).to be_instance_of(Hash)

      expect(serializable_hash[:included]).to be_instance_of(Array)
      expect(serializable_hash[:included][0]).to be_instance_of(Hash)
      expect(serializable_hash[:included].length).to eq 3

      serializable_hash = MovieSerializer.new(movie).serializable_hash

      expect(serializable_hash[:data]).to be_instance_of(Hash)
      expect(serializable_hash[:meta]).to be nil
      expect(serializable_hash[:included]).to be nil
    end

    it 'returns correct number of records when serialized_json is called for an array' do
      options = {}
      options[:meta] = { total: 2 }
      json = MovieSerializer.new([movie, movie], options).serialized_json
      serializable_hash = JSON.parse(json)
      expect(serializable_hash['data'].length).to eq 2
      expect(serializable_hash['meta']).to be_instance_of(Hash)
    end

    it 'returns correct id when serialized_json is called for a single object' do
      json = MovieSerializer.new(movie).serialized_json
      serializable_hash = JSON.parse(json)
      expect(serializable_hash['data']['id']).to eq movie.id.to_s
    end

    it 'returns correct json when serializing nil' do
      json = MovieSerializer.new(nil).serialized_json
      serializable_hash = JSON.parse(json)
      expect(serializable_hash['data']).to eq nil
    end

    it 'returns correct json when record id is nil' do
      movie.id = nil
      json = MovieSerializer.new(movie).serialized_json
      serializable_hash = JSON.parse(json)
      expect(serializable_hash['data']['id']).to be nil
    end

    it 'returns correct json when has_many returns []' do
      movie.actor_ids = []
      json = MovieSerializer.new(movie).serialized_json
      serializable_hash = JSON.parse(json)
      expect(serializable_hash['data']['relationships']['actors']['data'].length).to eq 0
    end

    it 'returns correct json when belongs_to returns nil' do
      movie.owner_id = nil
      json = MovieSerializer.new(movie).serialized_json
      serializable_hash = JSON.parse(json)
      expect(serializable_hash['data']['relationships']['owner']['data']).to be nil
    end

    it 'returns correct json when has_one returns nil' do
      supplier.account_id = nil
      json = SupplierSerializer.new(supplier).serialized_json
      serializable_hash = JSON.parse(json)
      expect(serializable_hash['data']['relationships']['account']['data']).to be nil
    end

    it 'returns correct json when serializing []' do
      json = MovieSerializer.new([]).serialized_json
      serializable_hash = JSON.parse(json)
      expect(serializable_hash['data']).to eq []
    end

    it 'returns errors when serializing with non-existent includes key' do
      options = {}
      options[:meta] = { total: 2 }
      options[:include] = [:blah_blah]
      expect { MovieSerializer.new([movie, movie], options).serializable_hash }.to raise_error(ArgumentError)
    end

    it 'returns keys when serializing with empty string/nil array includes key' do
      options = {}
      options[:meta] = { total: 2 }
      options[:include] = ['']
      expect(MovieSerializer.new([movie, movie], options).serializable_hash.keys).to eq [:data, :meta]
      options[:include] = [nil]
      expect(MovieSerializer.new([movie, movie], options).serializable_hash.keys).to eq [:data, :meta]
    end
  end

  context 'when testing included do block of object serializer' do
    it 'should set default_type based on serializer class name' do
      class BlahSerializer
        include FastJsonapi::ObjectSerializer
      end
      expect(BlahSerializer.record_type).to be :blah
    end

    it 'should set default_type for a multi word class name' do
      class BlahBlahSerializer
        include FastJsonapi::ObjectSerializer
      end
      expect(BlahBlahSerializer.record_type).to be :blah_blah
    end

    it 'shouldnt set default_type for a serializer that doesnt follow convention' do
      class BlahBlahSerializerBuilder
        include FastJsonapi::ObjectSerializer
      end
      expect(BlahBlahSerializerBuilder.record_type).to be_nil
    end

    it 'shouldnt set default_type for a serializer that doesnt follow convention' do
      module V1
        class BlahSerializer
          include FastJsonapi::ObjectSerializer
        end
      end
      expect(V1::BlahSerializer.record_type).to be :blah
    end
  end
end
