RSpec.shared_context 'movie class' do

  # Movie, Actor Classes and serializers
  before(:context) do
    # models
    class Movie
      attr_accessor :id,
                    :name,
                    :release_year,
                    :director,
                    :actor_ids,
                    :owner_id,
                    :movie_type_id

      def actors
        actor_ids.map.with_index do |id, i|
          a = Actor.new
          a.id = id
          a.name = "Test #{a.id}"
          a.email = "test#{a.id}@test.com"
          a.agency_id =i
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
      attr_accessor :id, :name, :email, :agency_id

      def agency
        Agency.new.tap do |a|
          a.id = agency_id
          a.name = "Test Agency #{agency_id}"
          a.state_id = 1
        end
      end

      def awards
        award_ids.map do |i|
          Award.new.tap do |a|
            a.id = i
            a.title = "Test Award #{i}"
            a.actor_id = id
          end
        end
      end

      def award_ids
        [id * 9, id * 9 + 1]
      end
    end

    class Agency
      attr_accessor :id, :name, :state_id

      def state
        State.new.tap do |s|
          s.id = state_id
          s.name = "Test State #{state_id}"
          s.agency_ids = [id]
        end
      end
    end

    class Award
      attr_accessor :id, :title, :actor_id
    end

    class State
      attr_accessor :id, :name, :agency_ids
    end

    class MovieType
      attr_accessor :id, :name
    end

    class Supplier
      attr_accessor :id, :account_id

      def account
        if account_id
          a = Account.new
          a.id = account_id
          a
        end
      end
    end

    class Account
      attr_accessor :id
    end

    # serializers
    class MovieSerializer
      include FastJsonapi::ObjectSerializer
      set_type :movie
      # director attr is not mentioned intentionally
      attributes :name, :release_year
      has_many :actors
      belongs_to :owner, record_type: :user
      belongs_to :movie_type
    end

    class MovieWithoutIdStructSerializer
      include FastJsonapi::ObjectSerializer
      attributes :name, :release_year
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
      has_many :awards
      belongs_to :agency
    end

    class AgencySerializer
      include FastJsonapi::ObjectSerializer
      attributes :id, :name
      belongs_to :city
    end

    class AwardSerializer
      include FastJsonapi::ObjectSerializer
      attributes :id, :title
      belongs_to :actor
    end

    class StateSerializer
      include FastJsonapi::ObjectSerializer
      attributes :id, :name
      has_many :agency
    end

    class MovieTypeSerializer
      include FastJsonapi::ObjectSerializer
      set_type :movie_type
      attributes :name
    end

    class SupplierSerializer
      include FastJsonapi::ObjectSerializer
      set_type :supplier
      has_one :account
    end

    class AccountSerializer
      include FastJsonapi::ObjectSerializer
      set_type :account
      belongs_to :supplier
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
      :id,
      :name,
      :release_year,
      :actor_ids,
      :actors,
      :owner_id,
      :owner,
      :movie_type_id
    )

    ActorStruct = Struct.new(:id, :name, :email, :agency_id, :award_ids)
    MovieWithoutIdStruct = Struct.new(:name, :release_year)
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
      MovieWithoutIdStruct
      HyphenMovieSerializer
      MovieWithoutIdStructSerializer
    ]
    classes_to_remove.each do |klass_name|
      Object.send(:remove_const, klass_name) if Object.constants.include?(klass_name)
    end
  end

  let(:movie_struct) do

    actors = []

    3.times.each do |id|
      actors << ActorStruct.new(id, id.to_s, id.to_s, id, [id])
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

  let(:movie_struct_without_id) do
    MovieWithoutIdStruct.new('struct without id', 2018)
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

  let(:actor) do
    Actor.new.tap do |a|
      a.id = 234
      a.name = 'test actor'
      a.email = 'test@test.com'
      a.agency_id = 432
    end
  end

  let(:supplier) do
    s = Supplier.new
    s.id = 1
    s.account_id = 1
    s
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
