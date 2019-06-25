# frozen_string_literal: true

RSpec.shared_context 'jsonapi movie class' do
  before(:context) do
    # models
    class JSONAPIMovie
      attr_accessor :id, :name, :release_year, :actors, :owner, :movie_type
    end

    class JSONAPIActor
      attr_accessor :id, :name, :email
    end

    class JSONAPIUser
      attr_accessor :id, :name
    end

    class JSONAPIMovieType
      attr_accessor :id, :name
    end

    # serializers
    class JSONAPIMovieSerializer < JSONAPI::Serializable::Resource
      type 'movie'
      attributes :name, :release_year

      has_many :actors
      has_one :owner
      belongs_to :movie_type
    end

    class JSONAPIActorSerializer < JSONAPI::Serializable::Resource
      type 'actor'
      attributes :name, :email
    end

    class JSONAPIUserSerializer < JSONAPI::Serializable::Resource
      type 'user'
      attributes :name
    end

    class JSONAPIMovieTypeSerializer < JSONAPI::Serializable::Resource
      type 'movie_type'
      attributes :name
    end

    class JSONAPISerializer
      def initialize(data, options = {})
        @serializer = JSONAPI::Serializable::Renderer.new
        @options = options.merge(class: {
                                   JSONAPIMovie: JSONAPIMovieSerializer,
                                   JSONAPIActor: JSONAPIActorSerializer,
                                   JSONAPIUser: JSONAPIUserSerializer,
                                   JSONAPIMovieType: JSONAPIMovieTypeSerializer
                                 })
        @data = data
      end

      def to_json(*_args)
        @serializer.render(@data, @options).to_json
      end

      def to_hash
        @serializer.render(@data, @options)
      end
    end
  end

  after :context do
    classes_to_remove = %i[
      JSONAPIMovie
      JSONAPIActor
      JSONAPIUser
      JSONAPIMovieType
      JSONAPIMovieSerializer
      JSONAPIActorSerializer
      JSONAPIUserSerializer
      JSONAPIMovieTypeSerializer
    ]
    classes_to_remove.each do |klass_name|
      Object.send(:remove_const, klass_name) if Object.constants.include?(klass_name)
    end
  end

  let(:jsonapi_actors) do
    3.times.map do |i|
      j = JSONAPIActor.new
      j.id = i + 1
      j.name = "Test #{j.id}"
      j.email = "test#{j.id}@test.com"
      j
    end
  end

  let(:jsonapi_user) do
    jsonapi_user = JSONAPIUser.new
    jsonapi_user.id = 3
    jsonapi_user
  end

  let(:jsonapi_movie_type) do
    jsonapi_movie_type = JSONAPIMovieType.new
    jsonapi_movie_type.id = 1
    jsonapi_movie_type.name = 'episode'
    jsonapi_movie_type
  end

  def build_jsonapi_movies(count)
    count.times.map do |i|
      m = JSONAPIMovie.new
      m.id = i + 1
      m.name = 'test movie'
      m.actors = jsonapi_actors
      m.owner = jsonapi_user
      m.movie_type = jsonapi_movie_type
      m
    end
  end
end
