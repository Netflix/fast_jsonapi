RSpec.shared_context 'movie class' do

  # Movie, Actor Classes and serializers
  before(:context) do
    # models
    class Movie
      attr_accessor :id, :name, :release_year, :actor_ids, :owner_id, :movie_type_id

      def actors
        actor_ids.map do |id|
          a = Actor.new
          a.id = id
          a.name = "Test #{a.id}"
          a.email = "test#{a.id}@test.com"
          a
        end
      end

      def movie_type
        mt = MovieType.new
        mt.id = movie_type_id
        mt.name = 'Episode'
        mt
      end

      def cache_key
        "#{id}"
      end
    end

    class Actor
      attr_accessor :id, :name, :email
    end

    class MovieType
      attr_accessor :id, :name
    end

    # serializers
    class MovieSerializer
      include FastJsonapi::ObjectSerializer
      set_type :movie
      attributes :name, :release_year
      has_many :actors
      belongs_to :owner, record_type: :user
      belongs_to :movie_type
    end

    class CachingMovieSerializer
      include FastJsonapi::ObjectSerializer
      set_type :movie
      attributes :name, :release_year
      has_many :actors
      belongs_to :owner, record_type: :user
      belongs_to :movie_type

      cache_options enabled: true
    end

    class CachingMovieWithHasManySerializer
      include FastJsonapi::ObjectSerializer
      set_type :movie
      attributes :name, :release_year
      has_many :actors, cached: true
      belongs_to :owner, record_type: :user
      belongs_to :movie_type

      cache_options enabled: true
    end

    class ActorSerializer
      include FastJsonapi::ObjectSerializer
      set_type :actor
      attributes :name, :email
    end

    class MovieTypeSerializer
      include FastJsonapi::ObjectSerializer
      set_type :movie_type
      attributes :name
    end
  end


  # Namespaced MovieSerializer
  before(:context) do
    # namespaced model stub
    module AppName
      module V1
        class MovieSerializer
          include FastJsonapi::ObjectSerializer
          # to test if compute_serializer_name works
        end
      end
    end
  end

  # Movie and Actor struct
  before(:context) do
    MovieStruct = Struct.new(
      :id, :name, :release_year, :actor_ids, :actors, :owner_id, :owner, :movie_type_id
    )

    ActorStruct = Struct.new(:id, :name, :email)
  end

  after(:context) do
    classes_to_remove = %i[
      Movie
      MovieSerializer
      Actor
      ActorSerializer
      MovieType
      MovieTypeSerializer
      AppName::V1::MovieSerializer
      MovieStruct
      ActorStruct
      HyphenMovieSerializer
    ]
    classes_to_remove.each do |klass_name|
      Object.send(:remove_const, klass_name) if Object.constants.include?(klass_name)
    end
  end

  let(:movie_struct) do

    actors = []

    3.times.each do |id|
      actors << ActorStruct.new(id, id.to_s, id.to_s)
    end

    m = MovieStruct.new
    m[:id] = 23
    m[:name] = 'struct movie'
    m[:release_year] = 1987
    m[:actor_ids] = [1,2,3]
    m[:owner_id] = 3
    m[:movie_type_id] = 2
    m[:actors] = actors
    m
  end

  let(:movie) do
    m = Movie.new
    m.id = 232
    m.name = 'test movie'
    m.actor_ids = [1, 2, 3]
    m.owner_id = 3
    m.movie_type_id = 1
    m
  end

  def build_movies(count)
    count.times.map do |i|
      m = Movie.new
      m.id = i + 1
      m.name = 'test movie'
      m.actor_ids = [1, 2, 3]
      m.owner_id = 3
      m.movie_type_id = 1
      m
    end
  end
end
