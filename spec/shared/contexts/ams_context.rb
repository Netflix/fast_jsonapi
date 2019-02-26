RSpec.shared_context "ams movie class" do
  before(:context) do
    # models
    class AMSModel < ActiveModelSerializers::Model
      derive_attributes_from_names_and_fix_accessors
    end

    class AMSMovieType < AMSModel
      attributes :id, :name, :movies
    end

    class AMSMovie < AMSModel
      attributes :id, :name, :release_year, :actors, :owner, :movie_type, :advertising_campaign

      def movie_type
        AMSMovieType.new do |movie_type|
          movie_type.id = 1
          movie_type.name = "Episode"
          movie_type.movies = [self]
        end
      end
    end

    class AMSAdvertisingCampaign < AMSModel
      attributes :id, :name, :movie
    end

    class AMSAward < AMSModel
      attributes :id, :title, :actor
    end

    class AMSAgency < AMSModel
      attributes :id, :name, :actors
    end

    class AMSActor < AMSModel
      attributes :id, :name, :email, :agency, :awards, :agency_id

      def agency
        AMSAgency.new.tap do |a|
          a.id = agency_id
          a.name = "Test Agency #{agency_id}"
        end
      end

      def award_ids
        [id * 9, id * 9 + 1]
      end

      def awards
        award_ids.map do |i|
          AMSAward.new.tap do |a|
            a.id = i
            a.title = "Test Award #{i}"
          end
        end
      end
    end

    class AMSUser < AMSModel
      attributes :id, :name
    end

    class AMSMovieType < AMSModel
      attributes :id, :name
    end

    # serializers
    class AMSAwardSerializer < ActiveModel::Serializer
      type "award"
      attributes :id, :title
      belongs_to :actor
    end

    class AMSAgencySerializer < ActiveModel::Serializer
      type "agency"
      attributes :id, :name
      belongs_to :state
      has_many :actors
    end

    class AMSActorSerializer < ActiveModel::Serializer
      type "actor"
      attributes :name, :email
      belongs_to :agency, serializer: ::AMSAgencySerializer
      has_many :awards, serializer: ::AMSAwardSerializer
    end

    class AMSUserSerializer < ActiveModel::Serializer
      type "user"
      attributes :name
    end

    class AMSMovieTypeSerializer < ActiveModel::Serializer
      type "movie_type"
      attributes :name
      has_many :movies
    end

    class AMSAdvertisingCampaignSerializer < ActiveModel::Serializer
      type "advertising_campaign"
      attributes :name
    end

    class AMSMovieSerializer < ActiveModel::Serializer
      type "movie"
      attributes :name, :release_year
      has_many :actors
      has_one :owner
      belongs_to :movie_type
      has_one :advertising_campaign
    end
  end

  after(:context) do
    %i[AMSMovie AMSMovieSerializer].each do |klass_name|
      Object.__send__(:remove_const, klass_name) if Object.constants.include?(klass_name)
    end
  end

  let(:ams_actors) do
    Array.new(3) do |i|
      AMSActor.new.tap do |a|
        a.id = i + 1
        a.name = "Test #{a.id}"
        a.email = "test#{a.id}@test.com"
        a.agency_id = i
      end
    end
  end

  let(:ams_user) do
    AMSUser.new.tap { |ams_user| ams_user.id = 3 }
  end

  let(:ams_movie_type) do
    AMSMovieType.new.tap do |ams_movie_type|
      ams_movie_type.id = 1
      ams_movie_type.name = "episode"
    end
  end

  let(:ams_advertising_campaign) do
    AMSAdvertisingCampaign.new.tap do |campaign|
      campaign.id = 1
      campaign.name = "Movie is incredible!!"
    end
  end

  def build_ams_movies(count)
    Array.new(count) do |i|
      AMSMovie.new.tap do |movie|
        movie.id = i + 1
        movie.name = "test movie"
        movie.actors = ams_actors
        movie.owner = ams_user
        movie.movie_type = ams_movie_type
        movie.advertising_campaign = ams_advertising_campaign
      end
    end
  end
end
