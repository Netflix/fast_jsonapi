require 'spec_helper'

describe FastJsonapi::ObjectSerializer do
  include_context 'movie class'

  context 'when including attribute blocks' do
    it 'returns correct hash when serializable_hash is called' do
      serializable_hash = MovieSerializerWithAttributeBlock.new([movie, movie]).serializable_hash
      expect(serializable_hash[:data].length).to eq 2
      expect(serializable_hash[:data][0][:attributes].length).to eq 3
      expect(serializable_hash[:data][0][:attributes]).to have_key(:title_with_year)
      expect(serializable_hash[:data][0][:attributes][:title_with_year]).to eq "#{movie.name} (#{movie.release_year})"

      serializable_hash = AMSMovieSerializerWithCustomMethod.new(movie_struct).serializable_hash
      expect(serializable_hash[:data][:attributes].length).to eq 3
      expect(serializable_hash[:data][:attributes]).to have_key(:title_with_year)
      expect(serializable_hash[:data][0][:attributes][:title_with_year]).to eq "#{movie.name} (#{movie.release_year})"
    end
  end
end
