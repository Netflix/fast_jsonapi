require 'spec_helper'

describe FastJsonapi::ObjectSerializer do
  include_context 'movie class'
  include_context 'ams movie class'

  before(:context) do
    [:dash, :camel, :camel_lower, :underscore].each do |transform_type|
      movie_serializer_name = "#{transform_type}_movie_serializer".classify
      movie_type_serializer_name = "#{transform_type}_movie_type_serializer".classify
      # https://stackoverflow.com/questions/4113479/dynamic-class-definition-with-a-class-name
      movie_serializer_class = Object.const_set(
        movie_serializer_name,
        Class.new {
        }
      )
      # https://rubymonk.com/learning/books/5-metaprogramming-ruby-ascent/chapters/24-eval/lessons/67-instance-eval
      movie_serializer_class.instance_eval do
        include FastJsonapi::ObjectSerializer
        set_type :movie
        set_key_transform transform_type
        attributes :name, :release_year
        has_many :actors
        belongs_to :owner, record_type: :user
        belongs_to :movie_type, record_type: :movie_type
      end
      movie_type_serializer_class = Object.const_set(
        movie_type_serializer_name,
        Class.new {
        }
      )
      movie_type_serializer_class.instance_eval do
        include FastJsonapi::ObjectSerializer
        set_key_transform transform_type
        set_type :movie_type
        attributes :name
      end
    end
  end

  context 'when using dashes for word separation in the JSON API members' do
    it 'returns correct hash when serializable_hash is called' do
      serializable_hash = DashMovieSerializer.new([movie, movie]).serializable_hash
      expect(serializable_hash[:data].length).to eq 2
      expect(serializable_hash[:data][0][:relationships].length).to eq 3
      expect(serializable_hash[:data][0][:relationships]).to have_key('movie-type'.to_sym)
      expect(serializable_hash[:data][0][:attributes].length).to eq 2
      expect(serializable_hash[:data][0][:attributes]).to have_key("release-year".to_sym)

      serializable_hash = DashMovieSerializer.new(movie_struct).serializable_hash
      expect(serializable_hash[:data][:relationships].length).to eq 3
      expect(serializable_hash[:data][:relationships]).to have_key('movie-type'.to_sym)
      expect(serializable_hash[:data][:attributes].length).to eq 2
      expect(serializable_hash[:data][:attributes]).to have_key('release-year'.to_sym)
      expect(serializable_hash[:data][:id]).to eq movie_struct.id.to_s
    end

    it 'returns type hypenated when trying to serializing a class with multiple words' do
      movie_type = MovieType.new
      movie_type.id = 3
      movie_type.name = "x"
      serializable_hash = DashMovieTypeSerializer.new(movie_type).serializable_hash
      expect(serializable_hash[:data][:type].to_sym).to eq 'movie-type'.to_sym
    end
  end

  context 'when using other key transforms' do
    [:camel, :camel_lower, :underscore, :dash].each do |transform_type|
      it "returns same thing as ams when using #{transform_type}" do
        ams_movie = build_ams_movies(1).first
        movie = build_movies(1).first
        movie_serializer_class = "#{transform_type}_movie_serializer".classify.constantize
        our_json = movie_serializer_class.new([movie]).serialized_json
        ams_json = ActiveModelSerializers::SerializableResource.new([ams_movie], key_transform: transform_type).to_json
        expect(our_json.length).to eq (ams_json.length)
      end
    end
  end

end
