require 'spec_helper'

describe FastJsonapi::ObjectSerializer do
  include_context 'movie class'

  context 'when including attribute blocks' do
    it 'returns correct hash when serializable_hash is called' do
      serializable_hash = MovieSerializerWithAttributeBlock.new([movie]).serializable_hash
      expect(serializable_hash[:data][0][:attributes][:name]).to eq movie.name
      expect(serializable_hash[:data][0][:attributes][:title_with_year]).to eq "#{movie.name} (#{movie.release_year})"
    end
  end
end
