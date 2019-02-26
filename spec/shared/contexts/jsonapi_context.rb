RSpec.shared_context "jsonapi movie class" do
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
      type "movie"
      attributes :name, :release_year

      has_many :actors
      has_one :owner
      belongs_to :movie_type
    end

    class JSONAPIActorSerializer < JSONAPI::Serializable::Resource
      type "actor"
      attributes :name, :email
    end

    class JSONAPIUserSerializer < JSONAPI::Serializable::Resource
      type "user"
      attributes :name
    end

    class JSONAPIMovieTypeSerializer < JSONAPI::Serializable::Resource
      type "movie_type"
      attributes :name
    end

    class JSONAPISerializer
      def initialize(data, options = {})
        @serializer = JSONAPI::Serializable::Renderer.new
        @options = options.merge(
          class: {
            JSONAPIMovie: JSONAPIMovieSerializer,
            JSONAPIActor: JSONAPIActorSerializer,
            JSONAPIUser: JSONAPIUserSerializer,
            JSONAPIMovieType: JSONAPIMovieTypeSerializer
          }
        )
        @data = data
      end

      def to_json
        @serializer.render(@data, @options).to_json
      end

      def to_hash
        @serializer.render(@data, @options)
      end
    end
  end

  after :context do
    %i[
      JSONAPIMovie
      JSONAPIActor
      JSONAPIUser
      JSONAPIMovieType
      JSONAPIMovieSerializer
      JSONAPIActorSerializer
      JSONAPIUserSerializer
      JSONAPIMovieTypeSerializer
    ].each do |klass_name|
      Object.__send__(:remove_const, klass_name) if Object.constants.include?(klass_name)
    end
  end

  let(:jsonapi_actors) do
    Array.new(3) do |i|
      JSONAPIActor.new.tap do |j|
        j.id = i + 1
        j.name = "Test #{j.id}"
        j.email = "test#{j.id}@test.com"
      end
    end
  end

  let(:jsonapi_user) do
    JSONAPIUser.new.tap { |user| user.id = 3 }
  end

  let(:jsonapi_movie_type) do
    JSONAPIMovieType.new.tap do |jsonapi_movie_type|
      jsonapi_movie_type.id = 1
      jsonapi_movie_type.name = "episode"
    end
  end

  def build_jsonapi_movies(count)
    Array.new(count) do |i|
      JSONAPIMovie.new.tap do |m|
        m.id = i + 1
        m.name = "test movie"
        m.actors = jsonapi_actors
        m.owner = jsonapi_user
        m.movie_type = jsonapi_movie_type
      end
    end
  end
end
