# frozen_string_literal: true

RSpec.shared_context 'ams movie class' do
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
        mt = AMSMovieType.new
        mt.id = 1
        mt.name = 'Episode'
        mt.movies = [self]
        mt
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
      type 'award'
      attributes :id, :title
      belongs_to :actor
    end
    class AMSAgencySerializer < ActiveModel::Serializer
      type 'agency'
      attributes :id, :name
      belongs_to :state
      has_many :actors
    end
    class AMSActorSerializer < ActiveModel::Serializer
      type 'actor'
      attributes :name, :email
      belongs_to :agency, serializer: ::AMSAgencySerializer
      has_many :awards, serializer: ::AMSAwardSerializer
    end
    class AMSUserSerializer < ActiveModel::Serializer
      type 'user'
      attributes :name
    end
    class AMSMovieTypeSerializer < ActiveModel::Serializer
      type 'movie_type'
      attributes :name
      has_many :movies
    end
    class AMSAdvertisingCampaignSerializer < ActiveModel::Serializer
      type 'advertising_campaign'
      attributes :name
    end
    class AMSMovieSerializer < ActiveModel::Serializer
      type 'movie'
      attributes :name, :release_year
      has_many :actors
      has_one :owner
      belongs_to :movie_type
      has_one :advertising_campaign
    end
  end

  after(:context) do
    classes_to_remove = %i[AMSMovie AMSMovieSerializer]
    classes_to_remove.each do |klass_name|
      Object.send(:remove_const, klass_name) if Object.constants.include?(klass_name)
    end
  end

  let(:ams_actors) do
    3.times.map do |i|
      a = AMSActor.new
      a.id = i + 1
      a.name = "Test #{a.id}"
      a.email = "test#{a.id}@test.com"
      a.agency_id = i
      a
    end
  end

  let(:ams_user) do
    ams_user = AMSUser.new
    ams_user.id = 3
    ams_user
  end

  let(:ams_movie_type) do
    ams_movie_type = AMSMovieType.new
    ams_movie_type.id = 1
    ams_movie_type.name = 'episode'
    ams_movie_type
  end

  let(:ams_advertising_campaign) do
    campaign = AMSAdvertisingCampaign.new
    campaign.id = 1
    campaign.name = 'Movie is incredible!!'
    campaign
  end

  def build_ams_movies(count)
    count.times.map do |i|
      m = AMSMovie.new
      m.id = i + 1
      m.name = 'test movie'
      m.actors = ams_actors
      m.owner = ams_user
      m.movie_type = ams_movie_type
      m.advertising_campaign = ams_advertising_campaign
      m
    end
  end
end
