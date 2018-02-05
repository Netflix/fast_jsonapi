RSpec.shared_context 'ams movie class' do
  before(:context) do
    # models
    class AMSMovie < ActiveModelSerializers::Model
      attr_accessor :id, :name, :release_year, :actors, :owner, :movie_type
    end

    class AMSActor < ActiveModelSerializers::Model
      attr_accessor :id, :name, :email
    end

    class AMSUser < ActiveModelSerializers::Model
      attr_accessor :id, :name
    end
    class AMSMovieType < ActiveModelSerializers::Model
      attr_accessor :id, :name
    end
    # serializers
    class AMSMovieSerializer < ActiveModel::Serializer
      type 'movie'
      attributes :name, :release_year
      has_many :actors
      has_one :owner
      belongs_to :movie_type
    end
    class AMSMovieSerializerWithCustomMethod < ActiveModel::Serializer
      type 'movie'
      attributes :name, :release_year, :title_with_year

      def title_with_year
        "#{object.name} (#{object.release_year})"
      end
    end

    class AMSActorSerializer < ActiveModel::Serializer
      type 'actor'
      attributes :name, :email
    end

    class AMSUserSerializer < ActiveModel::Serializer
      type 'user'
      attributes :name
    end
    class AMSMovieTypeSerializer < ActiveModel::Serializer
      type 'movie_type'
      attributes :name
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

  def build_ams_movies(count)
    count.times.map do |i|
      m = AMSMovie.new
      m.id = i + 1
      m.name = 'test movie'
      m.actors = ams_actors
      m.owner = ams_user
      m.movie_type = ams_movie_type
      m
    end
  end
end
