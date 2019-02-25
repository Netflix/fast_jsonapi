require "spec_helper"

describe FastJsonapi::ObjectSerializer do
  include_context "movie class"
  include_context "group class"

  context "when testing class methods of serialization core" do
    it "returns correct hash when id_hash is called" do
      inputs = [{ id: 23, record_type: :movie }, { id: "x", record_type: "person" }]
      inputs.each do |hash|
        result_hash = MovieSerializer.send(:id_hash, hash[:id])
        expect(result_hash[:id]).to eq hash[:id]
      end

      result_hash = MovieSerializer.send(:id_hash, nil)
      expect(result_hash).to be nil
    end

    it "returns correct hash when attributes_hash is called" do
      attributes_hash = MovieSerializer.send(:attributes_hash, movie)
      attribute_names = attributes_hash.keys.sort
      expect(attribute_names).to eq MovieSerializer.attributes_to_serialize.keys.sort
      MovieSerializer.attributes_to_serialize.each do |key, attribute|
        value = attributes_hash[key]
        expect(value).to eq movie.send(attribute.method)
      end
    end

    it "returns the correct empty result when relationships_hash is called" do
      movie.actor_ids = []
      movie.owner_id = nil
      relationships_hash = MovieSerializer.send(:relationships_hash, movie)
      expect(relationships_hash[:actors][:data]).to eq([])
      expect(relationships_hash[:owner][:data]).to eq(nil)
    end

    it "returns correct keys when relationships_hash is called" do
      relationships_hash = MovieSerializer.send(:relationships_hash, movie)
      relationship_names = relationships_hash.keys.sort
      relationships_hashes = MovieSerializer.relationships_to_serialize.values
      expected_names = relationships_hashes.map { |relationship| relationship.key }.sort
      expect(relationship_names).to eq expected_names
    end

    it "returns correct values when relationships_hash is called" do
      relationships_hash = MovieSerializer.relationships_hash(movie)
      actors_hash = movie.actor_ids.map { |id| { id: id } }
      owner_hash = { id: movie.owner_id }
      expect(relationships_hash[:actors][:data]).to match_array actors_hash
      expect(relationships_hash[:owner][:data]).to eq owner_hash
    end

    it "returns correct hash when record_hash is called" do
      record_hash = MovieSerializer.send(:record_hash, movie, nil)
      expect(record_hash[:id]).to eq movie.id
      expect(MovieSerializer.attributes_to_serialize).not_to be_empty
      MovieSerializer.attributes_to_serialize.each do |key, _|
        expect(record_hash).to have_key(key)
      end
      expect(record_hash).to have_key(:relationships) if MovieSerializer.relationships_to_serialize.present?
    end

    it "serializes known included records only once" do
      includes_list = [:actors]
      known_included_objects = {}
      included_records = []
      [movie, movie].each do |record|
        included_records.concat MovieSerializer.send(:get_included_records, record, includes_list, known_included_objects, {}, nil)
      end
      expect(included_records.size).to eq 3
    end
  end
end
