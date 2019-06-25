# frozen_string_literal: true

RSpec.shared_context 'jsonapi-serializers movie class' do
  before(:context) do
    # models
    class JSMovie
      attr_accessor :id, :name, :release_year, :actors, :owner, :movie_type
    end

    class JSActor
      attr_accessor :id, :name, :email
    end

    class JSUser
      attr_accessor :id, :name
    end

    class JSMovieType
      attr_accessor :id, :name
    end

    # serializers
    class JSActorSerializer
      include JSONAPI::Serializer
      attributes :name, :email

      def type
        'actor'
      end
    end
    class JSUserSerializer
      include JSONAPI::Serializer
      attributes :name

      def type
        'user'
      end
    end
    class JSMovieTypeSerializer
      include JSONAPI::Serializer
      attributes :name

      def type
        'movie_type'
      end
    end
    class JSMovieSerializer
      include JSONAPI::Serializer
      attributes :name, :release_year
      has_many :actors
      has_one :owner
      has_one :movie_type

      def type
        'movie'
      end
    end

    class JSONAPISSerializer
      def initialize(data, options = {})
        @options = options.merge(is_collection: true)
        @data = data
      end

      def to_json(*_args)
        JSONAPI::Serializer.serialize(@data, @options).to_json
      end

      def to_hash
        JSONAPI::Serializer.serialize(@data, @options)
      end
    end
  end

  after(:context) do
    classes_to_remove = %i[
      JSMovie
      JSActor
      JSUser
      JSMovieType
      JSONAPISSerializer
      JSActorSerializer
      JSUserSerializer
      JSMovieTypeSerializer
      JSMovieSerializer
    ]
    classes_to_remove.each do |klass_name|
      Object.send(:remove_const, klass_name) if Object.constants.include?(klass_name)
    end
  end

  let(:js_actors) do
    3.times.map do |i|
      a = JSActor.new
      a.id = i + 1
      a.name = "Test #{a.id}"
      a.email = "test#{a.id}@test.com"
      a
    end
  end

  let(:js_user) do
    ams_user = JSUser.new
    ams_user.id = 3
    ams_user
  end

  let(:js_movie_type) do
    ams_movie_type = JSMovieType.new
    ams_movie_type.id = 1
    ams_movie_type.name = 'episode'
    ams_movie_type
  end

  def build_js_movies(count)
    count.times.map do |i|
      m = JSMovie.new
      m.id = i + 1
      m.name = 'test movie'
      m.actors = js_actors
      m.owner = js_user
      m.movie_type = js_movie_type
      m
    end
  end
end
