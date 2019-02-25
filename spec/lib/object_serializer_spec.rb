require "spec_helper"

describe FastJsonapi::ObjectSerializer do
  include_context "movie class"
  include_context "group class"

  context "when testing instance methods of object serializer" do
    it "returns correct hash when serializable_hash is called" do
      options = {}
      options[:meta] = { total: 2 }
      options[:links] = { self: "self" }
      options[:include] = [:actors]
      serializable_hash = MovieSerializer.new([movie, movie], options).serializable_hash

      expect(serializable_hash[:data].length).to eq 2
      expect(serializable_hash[:data][0][:relationships].length).to eq 4

      expect(serializable_hash[:meta]).to be_instance_of(Hash)

      expect(serializable_hash[:included]).to be_instance_of(Array)
      expect(serializable_hash[:included][0]).to be_instance_of(Hash)
      expect(serializable_hash[:included].length).to eq 3

      serializable_hash = MovieSerializer.new(movie).serializable_hash

      expect(serializable_hash[:data]).to be_instance_of(Hash)
      expect(serializable_hash[:meta]).to be nil
      expect(serializable_hash[:included]).to be nil
    end

    it "returns correct nested includes when serializable_hash is called" do
      # 3 actors, 3 agencies
      include_object_total = 6

      options = {}
      options[:include] = [:actors, :"actors.agency"]
      serializable_hash = MovieSerializer.new([movie], options).serializable_hash

      expect(serializable_hash[:included]).to be_instance_of(Array)
      expect(serializable_hash[:included].length).to eq include_object_total
      (0..include_object_total - 1).each do |include|
        expect(serializable_hash[:included][include]).to be_instance_of(Hash)
      end

      options[:include] = [:"actors.agency"]
      serializable_hash = MovieSerializer.new([movie], options).serializable_hash

      expect(serializable_hash[:included]).to be_instance_of(Array)
      expect(serializable_hash[:included].length).to eq include_object_total
      (0..include_object_total - 1).each do |include|
        expect(serializable_hash[:included][include]).to be_instance_of(Hash)
      end
    end

    it "returns correct number of records when serialized_json is called for an array" do
      options = {}
      options[:meta] = { total: 2 }
      json = MovieSerializer.new([movie, movie], options).serialized_json
      serializable_hash = JSON.parse(json)
      expect(serializable_hash["data"].length).to eq 2
      expect(serializable_hash["meta"]).to be_instance_of(Hash)
    end

    it "returns correct id when serialized_json is called for a single object" do
      json = MovieSerializer.new(movie).serialized_json
      serializable_hash = JSON.parse(json)
      expect(serializable_hash["data"]["id"]).to eq movie.id
    end

    it "returns correct json when serializing nil" do
      json = MovieSerializer.new(nil).serialized_json
      serializable_hash = JSON.parse(json)
      expect(serializable_hash["data"]).to eq nil
    end

    it "returns correct json when record id is nil" do
      movie.id = nil
      json = MovieSerializer.new(movie).serialized_json
      serializable_hash = JSON.parse(json)
      expect(serializable_hash["data"]["id"]).to be nil
    end

    it "returns correct json when has_many returns []" do
      movie.actor_ids = []
      json = MovieSerializer.new(movie).serialized_json
      serializable_hash = JSON.parse(json)
      expect(serializable_hash["data"]["relationships"]["actors"]["data"].length).to eq 0
    end

    it "returns correct json when belongs_to returns nil" do
      movie.owner_id = nil
      json = MovieSerializer.new(movie).serialized_json
      serializable_hash = JSON.parse(json)
      expect(serializable_hash["data"]["relationships"]["owner"]["data"]).to be nil
    end

    it "returns correct json when belongs_to returns nil and there is a block for the relationship" do
      movie.owner_id = nil
      json = MovieSerializer.new(movie, include: [:owner]).serialized_json
      serializable_hash = JSON.parse(json)
      expect(serializable_hash["data"]["relationships"]["owner"]["data"]).to be nil
    end

    it "returns correct json when has_one returns nil" do
      supplier.account_id = nil
      json = SupplierSerializer.new(supplier).serialized_json
      serializable_hash = JSON.parse(json)
      expect(serializable_hash["data"]["relationships"]["account"]["data"]).to be nil
    end

    it "returns correct json when serializing []" do
      json = MovieSerializer.new([]).serialized_json
      serializable_hash = JSON.parse(json)
      expect(serializable_hash["data"]).to eq []
    end

    describe "#as_json" do
      it "returns a json hash" do
        json_hash = MovieSerializer.new(movie).as_json
        expect(json_hash["data"]["id"]).to eq movie.id
      end

      it "returns multiple records" do
        json_hash = MovieSerializer.new([movie, movie]).as_json
        expect(json_hash["data"].length).to eq 2
      end

      it "removes non-relevant attributes" do
        movie.director = "steven spielberg"
        json_hash = MovieSerializer.new(movie).as_json
        expect(json_hash["data"]["director"]).to eq(nil)
      end
    end

    it "returns errors when serializing with non-existent includes key" do
      options = {}
      options[:meta] = { total: 2 }
      options[:include] = [:blah_blah]
      expect { MovieSerializer.new([movie, movie], options).serializable_hash }.to raise_error(ArgumentError)
    end

    it "does not throw an error with non-empty string array includes key" do
      options = {}
      options[:include] = ["actors"]
      expect { MovieSerializer.new(movie, options) }.not_to raise_error
    end

    it "returns keys when serializing with empty string/nil array includes key" do
      options = {}
      options[:meta] = { total: 2 }
      options[:include] = [""]
      expect(MovieSerializer.new([movie, movie], options).serializable_hash.keys).to eq [:data, :meta]
      options[:include] = [nil]
      expect(MovieSerializer.new([movie, movie], options).serializable_hash.keys).to eq [:data, :meta]
    end
  end

  context "id attribute is the same for actors and not a primary key" do
    before do
      ActorSerializer.set_id :email
      movie.actor_ids = [0, 0, 0]
      class << movie
        def actors
          super.each_with_index { |actor, i| actor.email = "actor#{i}@email.com" }
        end
      end
    end

    after do
      ActorSerializer.set_id nil
    end

    let(:options) { { include: ["actors"] } }
    subject { MovieSerializer.new(movie, options).serializable_hash }

    it "returns all actors in includes" do
      expect(
        subject[:included].map { |i| i[:id] }
      ).to eq(
        movie.actors.map(&:email)
      )
    end
  end

  context "nested includes" do
    it "has_many to belongs_to: returns correct nested includes when serializable_hash is called" do
      # 3 actors, 3 agencies
      include_object_total = 6

      options = {}
      options[:include] = [:actors, :"actors.agency"]
      serializable_hash = MovieSerializer.new([movie], options).serializable_hash

      expect(serializable_hash[:included]).to be_instance_of(Array)
      expect(serializable_hash[:included].length).to eq include_object_total
      (0..include_object_total - 1).each do |include|
        expect(serializable_hash[:included][include]).to be_instance_of(Hash)
      end

      options[:include] = [:"actors.agency"]
      serializable_hash = MovieSerializer.new([movie], options).serializable_hash

      expect(serializable_hash[:included]).to be_instance_of(Array)
      expect(serializable_hash[:included].length).to eq include_object_total
      (0..include_object_total - 1).each do |include|
        expect(serializable_hash[:included][include]).to be_instance_of(Hash)
      end
    end

    it "`has_many` to `belongs_to` to `belongs_to` - returns correct nested includes when serializable_hash is called" do
      # 3 actors, 3 agencies, 1 state
      include_object_total = 7

      options = {}
      options[:include] = [:actors, :"actors.agency", :"actors.agency.state"]
      serializable_hash = MovieSerializer.new([movie], options).serializable_hash

      expect(serializable_hash[:included]).to be_instance_of(Array)
      expect(serializable_hash[:included].length).to eq include_object_total

      actors_serialized = serializable_hash[:included].map { |included| included[:id] }
      agencies_serialized = serializable_hash[:included].map { |included| included[:id] }
      states_serialized = serializable_hash[:included].map { |included| included[:id] }

      movie.actors.each do |actor|
        expect(actors_serialized).to include(actor.id)
      end

      agencies = movie.actors.map(&:agency).uniq
      agencies.each do |agency|
        expect(agencies_serialized).to include(agency.id)
      end

      states = agencies.map(&:state).uniq
      states.each do |state|
        expect(states_serialized).to include(state.id)
      end
    end

    it "has_many => has_one returns correct nested includes when serializable_hash is called" do
      options = {}
      options[:include] = [:movies, :"movies.advertising_campaign"]
      serializable_hash = MovieTypeSerializer.new([movie_type], options).serializable_hash

      movies_serialized = serializable_hash[:included].map { |included| included[:id] }
      advertising_campaigns_serialized = serializable_hash[:included].map { |included| included[:id] }

      movies = movie_type.movies
      movies.each do |movie|
        expect(movies_serialized).to include(movie.id)
      end

      advertising_campaigns = movies.map(&:advertising_campaign)
      advertising_campaigns.each do |advertising_campaign|
        expect(advertising_campaigns_serialized).to include(advertising_campaign.id)
      end
    end

    it "belongs_to: returns correct nested includes when nested attributes are nil when serializable_hash is called" do
      class Movie
        def advertising_campaign
          nil
        end
      end

      options = {}
      options[:include] = [:movies, :"movies.advertising_campaign"]

      serializable_hash = MovieTypeSerializer.new([movie_type], options).serializable_hash

      movies_serialized = serializable_hash[:included].map { |included| included[:id] }

      movies = movie_type.movies
      movies.each do |movie|
        expect(movies_serialized).to include(movie.id)
      end
    end

    it "polymorphic has_many: returns correct nested includes when serializable_hash is called" do
      options = {}
      options[:include] = [:groupees]

      serializable_hash = GroupSerializer.new([group], options).serializable_hash

      persons_serialized = serializable_hash[:included].map { |included| included[:id] }
      groups_serialized = serializable_hash[:included].map { |included| included[:id] }

      persons = group.groupees.find_all { |groupee| groupee.is_a?(Person) }
      persons.each do |person|
        expect(persons_serialized).to include(person.id)
      end

      groups = group.groupees.find_all { |groupee| groupee.is_a?(Group) }
      groups.each do |group|
        expect(groups_serialized).to include(group.id)
      end
    end
  end

  context "when testing included do block of object serializer" do
    it "should set default_type based on serializer class name" do
      class BlahSerializer
        include FastJsonapi::ObjectSerializer
      end
      expect(BlahSerializer.record_type).to be :blah
    end

    it "should set default_type for a multi word class name" do
      class BlahBlahSerializer
        include FastJsonapi::ObjectSerializer
      end
      expect(BlahBlahSerializer.record_type).to be :blah_blah
    end

    it "shouldn't set default_type for a serializer that doesnt follow convention" do
      class BlahBlahSerializerBuilder
        include FastJsonapi::ObjectSerializer
      end
      expect(BlahBlahSerializerBuilder.record_type).to be_nil
    end

    it "should set default_type for a namespaced serializer" do
      module V1
        class BlahSerializer
          include FastJsonapi::ObjectSerializer
        end
      end
      expect(V1::BlahSerializer.record_type).to be :blah
    end
  end

  context "when serializing included, serialize any links" do
    before do
      ActorSerializer.link(:self) { |actor_object| # rubocop:disable Style/SymbolProc
        actor_object.url
      }
    end
    subject(:serializable_hash) do
      options = {}
      options[:include] = [:actors]
      MovieSerializer.new(movie, options).serializable_hash
    end
    let(:actor) { movie.actors.first }
    let(:url) { "http://movies.com/actors/#{actor.id}" }

    it "returns correct hash when serializable_hash is called" do
      expect(serializable_hash[:included][0][:self]).to eq url
    end
  end

  context "when serializing included, params should be available in any serializer" do
    subject(:serializable_hash) do
      options = {}
      options[:include] = [:"actors.awards"]
      options[:params] = { include_award_year: true }
      MovieSerializer.new(movie, options).serializable_hash
    end
    let(:actor) { movie.actors.first }
    let(:award) { actor.awards.first }
    let(:year) { award.year }

    it "passes params to deeply nested includes" do
      expect(year).to_not be_blank
      expect(serializable_hash[:included][0][:year]).to eq year
    end
  end

  context "when is_collection option present" do
    subject { MovieSerializer.new(resource, is_collection_options).serializable_hash }

    context "autodetect" do
      let(:is_collection_options) { {} }

      context "collection if no option present" do
        let(:resource) { [movie] }
        it { expect(subject[:data]).to be_a(Array) }
      end

      context "single if no option present" do
        let(:resource) { movie }
        it { expect(subject[:data]).to be_a(Hash) }
      end
    end

    context "force is_collection to true" do
      let(:is_collection_options) { { is_collection: true } }

      context "collection will pass" do
        let(:resource) { [movie] }
        it { expect(subject[:data]).to be_a(Array) }
      end

      context "single will raise error" do
        let(:resource) { movie }
        it { expect { subject }.to raise_error(NoMethodError, /method(.*)each/) }
      end
    end

    context "force is_collection to false" do
      let(:is_collection_options) { { is_collection: false } }

      context "collection will fail without id" do
        let(:resource) { [movie] }
        it { expect { subject }.to raise_error(FastJsonapi::MandatoryField, /id is a mandatory field/) }
      end

      context "single will pass" do
        let(:resource) { movie }
        it { expect(subject[:data]).to be_a(Hash) }
      end
    end
  end

  context "when optional attributes are determined by record data" do
    it "returns optional attribute when attribute is included" do
      movie.release_year = 2001
      json = MovieOptionalRecordDataSerializer.new(movie).serialized_json
      serializable_hash = JSON.parse(json)
      expect(serializable_hash["data"]["release_year"]).to eq movie.release_year
    end

    it "doesn't return optional attribute when attribute is not included" do
      movie.release_year = 1970
      json = MovieOptionalRecordDataSerializer.new(movie).serialized_json
      serializable_hash = JSON.parse(json)
      expect(serializable_hash["data"].key?("release_year")).to be_falsey
    end
  end

  context "when optional attributes are determined by params data" do
    it "returns optional attribute when attribute is included" do
      movie.director = "steven spielberg"
      json = MovieOptionalParamsDataSerializer.new(movie, params: { admin: true }).serialized_json
      serializable_hash = JSON.parse(json)
      expect(serializable_hash["data"]["director"]).to eq "steven spielberg"
    end

    it "doesn't return optional attribute when attribute is not included" do
      movie.director = "steven spielberg"
      json = MovieOptionalParamsDataSerializer.new(movie, params: { admin: false }).serialized_json
      serializable_hash = JSON.parse(json)
      expect(serializable_hash["data"].key?("director")).to be_falsey
    end
  end

  context "when optional relationships are determined by record data" do
    it "returns optional relationship when relationship is included" do
      json = MovieOptionalRelationshipSerializer.new(movie).serialized_json
      serializable_hash = JSON.parse(json)
      expect(serializable_hash["data"]["relationships"].key?("actors")).to be_truthy
    end

    context "when relationship is not included" do
      let(:json) {
        MovieOptionalRelationshipSerializer.new(movie, options).serialized_json
      }
      let(:options) {
        {}
      }
      let(:serializable_hash) {
        JSON.parse(json)
      }

      it "doesn't return optional relationship" do
        movie.actor_ids = []
        expect(serializable_hash["data"]["relationships"].key?("actors")).to be_falsey
      end

      it "doesn't include optional relationship" do
        movie.actor_ids = []
        options[:include] = [:actors]
        expect(serializable_hash["included"]).to be_blank
      end
    end
  end

  context "when optional relationships are determined by params data" do
    it "returns optional relationship when relationship is included" do
      json = MovieOptionalRelationshipWithParamsSerializer.new(movie, params: { admin: true }).serialized_json
      serializable_hash = JSON.parse(json)
      expect(serializable_hash["data"]["relationships"].key?("owner")).to be_truthy
    end

    context "when relationship is not included" do
      let(:json) {
        MovieOptionalRelationshipWithParamsSerializer.new(movie, options).serialized_json
      }
      let(:options) {
        { params: { admin: false } }
      }
      let(:serializable_hash) {
        JSON.parse(json)
      }

      it "doesn't return optional relationship" do
        expect(serializable_hash["data"]["relationships"].key?("owner")).to be_falsey
      end

      it "doesn't include optional relationship" do
        options[:include] = [:owner]
        expect(serializable_hash["included"]).to be_blank
      end
    end
  end

  context "when attribute contents are determined by params data" do
    it "does not throw an error with no params are passed" do
      expect { MovieOptionalAttributeContentsWithParamsSerializer.new(movie).serialized_json }.not_to raise_error
    end
  end
end
