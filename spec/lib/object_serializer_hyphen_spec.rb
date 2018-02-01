require 'spec_helper'

describe FastJsonapi::ObjectSerializer do
  include_context 'movie class'
  include_context 'ams movie class'

  context 'when using hyphens for word separation in the JSON API members' do
    it 'returns correct hash when serializable_hash is called' do
      serializable_hash = HyphenMovieSerializer.new([movie, movie]).serializable_hash
      expect(serializable_hash[:data].length).to eq 2
      expect(serializable_hash[:data][0][:relationships].length).to eq 3
      expect(serializable_hash[:data][0][:relationships]).to have_key('movie-type'.to_sym)
      expect(serializable_hash[:data][0][:attributes].length).to eq 2
      expect(serializable_hash[:data][0][:attributes]).to have_key("release-year".to_sym)

      serializable_hash = HyphenMovieSerializer.new(movie_struct).serializable_hash
      expect(serializable_hash[:data][:relationships].length).to eq 3
      expect(serializable_hash[:data][:relationships]).to have_key('movie-type'.to_sym)
      expect(serializable_hash[:data][:attributes].length).to eq 2
      expect(serializable_hash[:data][:attributes]).to have_key('release-year'.to_sym)
      expect(serializable_hash[:data][:id]).to eq movie_struct.id.to_s
    end

    it 'returns same thing as ams' do
      ams_movie = build_ams_movies(1).first
      movie = build_movies(1).first
      our_json = HyphenMovieSerializer.new([movie]).serialized_json
      ams_json = ActiveModelSerializers::SerializableResource.new([ams_movie], key_transform: :dash).to_json
      expect(our_json.length).to eq (ams_json.length)
    end

    it 'returns type hypenated when trying to serializing a class with multiple words' do
      movie_type = MovieType.new
      movie_type.id = 3
      movie_type.name = "x"
      serializable_hash = HyphenMovieTypeSerializer.new(movie_type).serializable_hash
      expect(serializable_hash[:data][:type].to_sym).to eq 'movie-type'.to_sym
    end
  end
end
