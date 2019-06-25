# frozen_string_literal: true

require 'spec_helper'

describe FastJsonapi::ObjectSerializer do
  include_context 'movie class'

  context 'when testing object serializer with ruby struct' do
    it 'returns correct hash when serializable_hash is called' do
      options = {}
      options[:meta] = { total: 2 }
      options[:links] = { self: 'self' }
      options[:include] = [:actors]
      serializable_hash = MovieSerializer.new([movie_struct, movie_struct], options).serializable_hash

      expect(serializable_hash[:data].length).to eq 2
      expect(serializable_hash[:data][0][:relationships].length).to eq 4
      expect(serializable_hash[:data][0][:attributes].length).to eq 2

      expect(serializable_hash[:meta]).to be_instance_of(Hash)
      expect(serializable_hash[:links]).to be_instance_of(Hash)

      expect(serializable_hash[:included]).to be_instance_of(Array)
      expect(serializable_hash[:included][0]).to be_instance_of(Hash)
      expect(serializable_hash[:included].length).to eq 3

      serializable_hash = MovieSerializer.new(movie_struct).serializable_hash

      expect(serializable_hash[:data]).to be_instance_of(Hash)
      expect(serializable_hash[:meta]).to be nil
      expect(serializable_hash[:links]).to be nil
      expect(serializable_hash[:included]).to be nil
      expect(serializable_hash[:data][:id]).to eq movie_struct.id.to_s
    end

    context 'struct without id' do
      it 'returns correct hash when serializable_hash is called' do
        serializer = MovieWithoutIdStructSerializer.new(movie_struct_without_id)
        expect { serializer.serializable_hash }.to raise_error(FastJsonapi::MandatoryField)
      end
    end
  end
end
