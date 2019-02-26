require "spec_helper"

describe FastJsonapi::ObjectSerializer do
  include_context "movie class"

  context "when caching has_many" do
    before(:each) do
      rails = OpenStruct.new
      rails.cache = ActiveSupport::Cache::MemoryStore.new
      stub_const("Rails", rails)
    end

    it "returns correct hash when serializable_hash is called" do
      options = {}
      options[:meta] = { total: 2 }
      options[:links] = { self: "self" }

      options[:include] = [:actors]
      serializable_hash = CachingMovieSerializer.new([movie, movie], options).serializable_hash

      expect(serializable_hash[:data].length).to eq 2
      expect(serializable_hash[:data][0].length).to eq 6

      expect(serializable_hash[:meta]).to be_instance_of(Hash)
      expect(serializable_hash[:links]).to be_instance_of(Hash)

      expect(serializable_hash[:data][0]).to be_instance_of(Hash)
      expect(serializable_hash[:data][0][:actors]).to be_instance_of(Array)
      expect(serializable_hash[:data][0][:actors].length).to eq 3

      serializable_hash = CachingMovieSerializer.new(movie).serializable_hash

      expect(serializable_hash[:data]).to be_instance_of(Hash)
      expect(serializable_hash[:meta]).to be nil
      expect(serializable_hash[:links]).to be nil
    end

    it "uses cached values for the record" do
      previous_name = movie.name
      previous_actors = movie.actors
      CachingMovieSerializer.new(movie).serializable_hash

      movie.name = "should not match"
      allow(movie).to receive(:actor_ids).and_return([99])

      expect(previous_name).not_to eq(movie.name)
      expect(previous_actors).not_to eq(movie.actors)
      serializable_hash = CachingMovieSerializer.new(movie).serializable_hash

      expect(serializable_hash[:data][:name]).to eq(previous_name)
      expect(serializable_hash[:data][:actors].length).to eq movie.actors.length
    end

    it "uses cached values for has many as specified" do
      previous_name = movie.name
      previous_actors = movie.actors
      CachingMovieWithHasManySerializer.new(movie).serializable_hash

      movie.name = "should not match"
      allow(movie).to receive(:actor_ids).and_return([99])

      expect(previous_name).not_to eq(movie.name)
      expect(previous_actors).not_to eq(movie.actors)
      serializable_hash = CachingMovieWithHasManySerializer.new(movie).serializable_hash

      expect(serializable_hash[:data][:name]).to eq(previous_name)
      expect(serializable_hash[:data][:actors].length).to eq previous_actors.length
    end
  end
end
