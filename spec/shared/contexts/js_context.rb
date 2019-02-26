RSpec.shared_context "jsonapi-serializers movie class" do
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
        "actor"
      end
    end

    class JSUserSerializer
      include JSONAPI::Serializer
      attributes :name

      def type
        "user"
      end
    end

    class JSMovieTypeSerializer
      include JSONAPI::Serializer
      attributes :name

      def type
        "movie_type"
      end
    end

    class JSMovieSerializer
      include JSONAPI::Serializer
      attributes :name, :release_year
      has_many :actors
      has_one :owner
      has_one :movie_type

      def type
        "movie"
      end
    end

    class JSONAPISSerializer
      def initialize(data, options = {})
        @options = options.merge(is_collection: true)
        @data = data
      end

      def to_json
        JSONAPI::Serializer.serialize(@data, @options).to_json
      end

      def to_hash
        JSONAPI::Serializer.serialize(@data, @options)
      end
    end
  end

  after(:context) do
    %i[
      JSMovie
      JSActor
      JSUser
      JSMovieType
      JSONAPISSerializer
      JSActorSerializer
      JSUserSerializer
      JSMovieTypeSerializer
      JSMovieSerializer
    ].each do |klass_name|
      Object.__send__(:remove_const, klass_name) if Object.constants.include?(klass_name)
    end
  end

  let(:js_actors) do
    Array.new(3) do |i|
      JSActor.new.tap do |a|
        a.id = i + 1
        a.name = "Test #{a.id}"
        a.email = "test#{a.id}@test.com"
      end
    end
  end

  let(:js_user) do
    JSUser.new.tap { |ams_user| ams_user.id = 3 }
  end

  let(:js_movie_type) do
    JSMovieType.new.tap do |ams_movie_type|
      ams_movie_type.id = 1
      ams_movie_type.name = "episode"
    end
  end

  def build_js_movies(count)
    Array.new(count) do |i|
      JSMovie.new.tap do |m|
        m.id = i + 1
        m.name = "test movie"
        m.actors = js_actors
        m.owner = js_user
        m.movie_type = js_movie_type
      end
    end
  end
end
