require "spec_helper"

describe FastJsonapi::ObjectSerializer do
  include_context "movie class"
  include_context "group class"

  let(:actors_total) { 3 }
  let(:agencies_total) { 3 }
  let(:states_total) { 1 }

  context "when testing instance methods of object serializer" do
    it "returns correct hash when serializable_hash is called" do
      options = {
        meta: { total: 2 },
        links: { self: "self" },
        include: :actors
      }
      serializable_hash = MovieSerializer.new([movie, movie], options).serializable_hash

      expect(serializable_hash[:data].length).to eq 2
      expect(serializable_hash[:data][0].length).to eq 7

      expect(serializable_hash[:meta]).to be_instance_of(Hash)

      expect(serializable_hash[:data][0][:actors]).to be_instance_of(Array)
      expect(serializable_hash[:data][0][:actors][0]).to be_instance_of(Hash)
      expect(serializable_hash[:data][0][:actors].length).to eq 3

      serializable_hash = MovieSerializer.new(movie).serializable_hash

      expect(serializable_hash[:data]).to be_instance_of(Hash)
      expect(serializable_hash[:meta]).to be nil
    end

    it "returns correct nested includes when serializable_hash is called" do
      options = {
        include: { actors: :agency }
      }
      serializable_hash = MovieSerializer.new([movie], options).serializable_hash

      expect(serializable_hash[:data][0][:actors]).to be_instance_of(Array)
      expect(serializable_hash[:data][0][:actors].length).to eq actors_total
      (0..actors_total - 1).each do |include|
        expect(serializable_hash[:data][0][:actors][include]).to be_instance_of(Hash)
      end
    end

    it "returns correct number of records when serialized_json is called for an array" do
      options = {
        meta: { total: 2 }
      }
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
      expect(serializable_hash["data"]["actors"].length).to eq 0
    end

    it "returns correct json when belongs_to returns nil" do
      movie.owner_id = nil
      json = MovieSerializer.new(movie).serialized_json
      serializable_hash = JSON.parse(json)
      expect(serializable_hash["data"]["owner"]).to be nil
    end

    it "returns correct json when belongs_to returns nil and there is a block for the relationship" do
      movie.owner_id = nil
      json = MovieSerializer.new(movie, include: [:owner]).serialized_json
      serializable_hash = JSON.parse(json)
      expect(serializable_hash["data"]["owner"]).to be nil
    end

    it "returns correct json when has_one returns nil" do
      supplier.account_id = nil
      json = SupplierSerializer.new(supplier).serialized_json
      serializable_hash = JSON.parse(json)
      expect(serializable_hash["data"]["account"]).to be nil
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
      expect(subject[:data][:actors].map { |i| i[:id] }).to eq(movie.actors.map(&:email))
    end
  end

  context "nested includes" do
    describe "#normalize_includes!" do
      subject { MovieSerializer.new(movie, include: includes).instance_exec { @includes } }

      before do
        allow_any_instance_of(MovieSerializer).to(
          receive(:validate_includes!).and_return(true)
        )
      end

      context "when include is empty" do
        let(:includes) { nil }
        it { is_expected.to eq({}) }
      end

      context "when include is a string" do
        let(:includes) { "foobar" }
        it { is_expected.to eq foobar: {} }
      end

      context "when include has an array of strings" do
        let(:includes) { %w[foo bar] }
        it { is_expected.to eq foo: {}, bar: {} }
      end

      context "when include is a hash" do
        let(:includes) { { foo: :bar } }
        it { is_expected.to eq foo: { bar: {} } }
      end

      context "when include is an array of hashes" do
        let(:includes) { [{ foo: :bar }, { baz: nil }] }
        it { is_expected.to eq foo: { bar: {} }, baz: {} }
      end

      context "when include is a mix of strings and hashes" do
        let(:includes) { [{ foo: :bar }, "baz"] }
        it { is_expected.to eq foo: { bar: {} }, baz: {} }
      end

      context "when include is a hash with an array" do
        let(:includes) { { foo: %w[bar baz] } }
        it { is_expected.to eq foo: { bar: {}, baz: {} } }
      end

      context "when include is ridonculous" do
        let(:includes) do
          ["blah", { "bah" => "licious" }, { foo: { bar: { baz: [:fee, :fi], fo: :fum } }, foobar: nil }]
        end

        it do
          is_expected.to eq(
            blah: {},
            bah: { licious: {} },
            foo: {
              bar: {
                baz: { fee: {}, fi: {} },
                fo: { fum: {} }
              }
            },
            foobar: {}
          )
        end
      end
    end

    let(:actors_total) { 3 }
    let(:agencies_total) { 3 }
    let(:states_total) { 1 }

    let(:serializable_movie) { MovieSerializer.new([movie], options).serializable_hash }
    let(:serializable_movie_type) { MovieTypeSerializer.new([movie_type], options).serializable_hash }
    let(:serializable_group) { GroupSerializer.new([group], options).serializable_hash }

    context "when include is has_many to belongs_to" do
      let(:options) { { include: { actors: :agency } } }
      let(:serializable_hash) { serializable_movie }

      it "returns correct nested includes when serializable_hash is called" do
        expect(serializable_hash[:data][0][:actors]).to be_instance_of(Array)
        expect(serializable_hash[:data][0][:actors].length).to eq actors_total

        expect(
          serializable_hash[:data][0][:actors].map { |actor| actor[:agency] }.compact.length
        ).to eq agencies_total

        (0..agencies_total - 1).each do |include|
          expect(serializable_hash[:data][0][:actors][include][:agency]).to be_instance_of(Hash)
        end
      end
    end

    context "when `has_many` to `belongs_to` to `belongs_to`" do
      let(:options) { { include: { actors: { agency: :state } } } }
      let(:serializable_hash) { serializable_movie }

      it "returns correct nested includes when serializable_hash is called" do
        expect(serializable_hash[:data][0][:actors]).to be_instance_of(Array)
        expect(serializable_hash[:data][0][:actors].length).to eq actors_total

        agencies_serialized = serializable_hash[:data][0][:actors].map { |actor| actor[:agency] }
        expect(agencies_serialized.length).to eq agencies_total

        states_serialized = agencies_serialized.map { |agency| agency[:state][:name] }.compact
        expect(states_serialized.length).to eq states_total
      end
    end

    context "when `has_many` to `has_one`" do
      let(:options) { { include: { movies: :advertising_campaign } } }
      let(:serializable_hash) { serializable_movie_type }

      it "returns correct nested includes when serializable_hash is called" do
        movies_serialized = serializable_hash[:data].flat_map do |type|
          type[:movies].flat_map { |included| included[:id] }
        end

        advertising_campaigns_serialized = serializable_hash[:data].map { |included| included[:id] }

        movies = movie_type.movies
        movies.each do |movie|
          expect(movies_serialized).to include(movie.id)
        end

        advertising_campaigns = movies.map(&:advertising_campaign)
        advertising_campaigns.each do |advertising_campaign|
          expect(advertising_campaigns_serialized).to include(advertising_campaign.id)
        end
      end
    end

    context "when `belongs_to` nested attributes are nil" do
      let(:options) { { include: { movies: :advertising_campaign } } }
      let(:serializable_hash) { serializable_movie_type }

      it "returns correct nested includes when serializable_hash is called" do
        class Movie
          def advertising_campaign
            nil
          end
        end

        movies_serialized = serializable_hash[:data].flat_map do |type|
          type[:movies].map { |included| included[:id] }
        end

        movies = movie_type.movies
        movies.each do |movie|
          expect(movies_serialized).to include(movie.id)
        end
      end
    end

    context "when polymorphic `has_many`" do
      let(:options) { { include: :groupees } }
      let(:serializable_hash) { serializable_group }

      it "returns correct nested includes when serializable_hash is called" do
        persons_serialized = serializable_hash[:data].map { |included| included[:id] }
        groups_serialized = serializable_hash[:data].flat_map do |person|
          person[:groupees].map { |included| included[:id] }
        end

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
      expect(serializable_hash[:data][:actors][0][:self]).to eq url
    end
  end

  context "when serializing included, params should be available in any serializer" do
    subject(:serializable_hash) do
      options = {}
      options[:include] = { actors: :awards }
      options[:params] = { include_award_year: true }
      MovieSerializer.new(movie, options).serializable_hash
    end
    let(:actor) { movie.actors.first }
    let(:award) { actor.awards.first }
    let(:year) { award.year }

    it "passes params to deeply nested includes" do
      expect(year).to_not be_blank
      expect(serializable_hash[:data][:actors][0][:awards][0][:year]).to eq year
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
      expect(serializable_hash["data"].key?("actors")).to be_truthy
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
        expect(serializable_hash["data"].key?("actors")).to be_falsey
      end

      it "doesn't include optional relationship" do
        movie.actor_ids = []
        options[:include] = [:actors]
        expect(serializable_hash["data"]["actors"]).to be_blank
      end
    end
  end

  context "when optional relationships are determined by params data" do
    it "returns optional relationship when relationship is included" do
      json = MovieOptionalRelationshipWithParamsSerializer.new(movie, params: { admin: true }).serialized_json
      serializable_hash = JSON.parse(json)
      expect(serializable_hash["data"].key?("owner")).to be_truthy
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
        expect(serializable_hash["data"].key?("owner")).to be_falsey
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
