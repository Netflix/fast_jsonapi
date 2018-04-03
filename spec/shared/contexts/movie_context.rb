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
        actor_ids.map do |id|
          a = Actor.new
          a.id = id
          a.name = "Test #{a.id}"
          a.email = "test#{a.id}@test.com"
          a.agency_id = 1
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
        ag = Agency.new
        ag.id = agency_id
        ag.name = 'Talent Agency Inc.'
        ag
      end
    end

    class MovieType
      attr_accessor :id, :name
    end

    class Agency
      attr_accessor :id, :name, :actor_ids
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
      belongs_to :agency
    end

    class MovieTypeSerializer
      include FastJsonapi::ObjectSerializer
      set_type :movie_type
      attributes :name
    end

    class MovieSerializerWithAttributeBlock
      include FastJsonapi::ObjectSerializer
      set_type :movie
      attributes :name, :release_year
      attribute :title_with_year do |record|
        "#{record.name} (#{record.release_year})"
      end
    end

    class AgencySerializer
      include FastJsonapi::ObjectSerializer
      attributes :id, :name
      has_many :actors
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

    ActorStruct = Struct.new(:id, :name, :email, :agency_id)

    AgencyStruct = Struct.new(:id, :name, :actor_ids)
  end

  after(:context) do
    classes_to_remove = %i[
      Movie
      MovieSerializer
      Actor
      ActorSerializer
      MovieType
      MovieTypeSerializer
      MovieSerializerWithAttributeBlock
      AppName::V1::MovieSerializer
      MovieStruct
      ActorStruct
      HyphenMovieSerializer
      Agency
      AgencyStruct
      AgencySerializer
    ]
    classes_to_remove.each do |klass_name|
      Object.send(:remove_const, klass_name) if Object.constants.include?(klass_name)
    end
  end

  let(:movie_struct) do

    agency = AgencyStruct

    actors = []

    3.times.each do |id|
      actors << ActorStruct.new(id, id.to_s, id.to_s, id.to_s)
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
