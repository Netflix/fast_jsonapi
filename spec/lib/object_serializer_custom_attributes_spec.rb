require 'spec_helper'

describe FastJsonapi::ObjectSerializer do
  before(:context) do
    # models
    class Movie
      attr_accessor :id, :name
    end

    # serializers
    class MovieSerializer
      include FastJsonapi::ObjectSerializer
      attributes :id, :name, :review

      def review
        "#{object.name} was awesome!!"
      end
    end
  end

  after(:context) do
    classes_to_remove = %i[
      Movie
      MovieSerializer
    ]
    classes_to_remove.each do |klass_name|
      Object.send(:remove_const, klass_name) if Object.constants.include?(klass_name)
    end
  end

  let(:movie) do
    m = Movie.new
    m.id = 1
    m.name = 'Titanic'
    m
  end

  context 'when testing custom attributes feature' do
    it 'should return the right output for the custom attribute' do
      movie_hash = MovieSerializer.new(movie).record_hash(movie)
      expect(movie_hash[:attributes].keys.length).to be 3
      expect(movie_hash[:attributes][:review]).to eq 'Titanic was awesome!!'
    end
  end

end
