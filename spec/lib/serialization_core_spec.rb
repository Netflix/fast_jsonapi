require 'spec_helper'

describe FastJsonapi::SerializationCore do
  include_context 'movie class'
  include_context 'group class'

  describe '#self.id_hash' do
    subject(:id_hash) { MovieSerializer.id_hash(id, 'movie') }

    context 'when id is string' do
      let(:id) { 'x' }

      it 'returns id_hash' do
        expect(id_hash[:id]).to eq 'x'
        expect(id_hash[:type]).to eq 'movie'
      end
    end

    context 'when id is int' do
      let(:id) { 23 }

      it 'turns id into string' do
        expect(id_hash[:id]).to eq '23'
        expect(id_hash[:type]).to eq 'movie'
      end
    end

    context 'when id is blank' do
      let(:id) { nil }

      it { is_expected.to be_nil }
    end
  end

  describe '#self.ids_hash' do
    subject(:ids_hash) { MovieSerializer.ids_hash(ids, :movie) }

    context 'when ids is an array of ids' do
      let(:ids) { %w(1 2 3) }

      it 'returns correct array' do
        expect(ids_hash.count).to eq 3
        expect(ids_hash).to include({ id: '1', type: :movie }, { id: '2', type: :movie }, { id: '3', type: :movie })
      end
    end

    context 'when ids is an empty array' do
      let(:ids) { [] }

      it 'returns empty array' do
        expect(ids_hash).to be_empty
      end
    end

    context 'when ids is just a single id' do
      let(:ids) { '1' }

      it 'returns correct hash' do
        expect(ids_hash[:id]).to eq '1'
        expect(ids_hash[:type]).to eq :movie
      end
    end

    context 'when ids is nil' do
      let(:ids) { nil }

      it 'returns correct hash' do
        expect(ids_hash).to be_nil
      end
    end
  end

  describe '#self.ids_hash_from_record_and_relationship' do
    context 'when an association is not polymorphic' do
      subject(:ids_hash) { MovieSerializer.ids_hash_from_record_and_relationship(movie, relationship) }

      let(:relationship) { { name: :actors, relationship_type: :has_many, object_method_name: :actors, id_method_name: :actor_ids, record_type: :actor } }

      it 'returns the correct hash' do
        expect(ids_hash.count).to eq 3
        expect(ids_hash).to include({ id: '1', type: :actor }, { id: '2', type: :actor }, { id: '3', type: :actor })
      end
    end

    context 'when an association is polymorphic' do
      subject(:ids_hash) { GroupSerializer.ids_hash_from_record_and_relationship(group, relationship) }

      let(:relationship) { { name: :groupees, relationship_type: :has_many, object_method_name: :groupees, polymorphic: {} } }

      it 'returns the correct hash' do
        expect(ids_hash.count).to eq 2
        expect(ids_hash).to include({ id: '1', type: :person }, { id: '2', type: :group })
      end
    end
  end

  describe '#self.attributes_hash' do
    subject(:attributes_hash) { MovieSerializer.attributes_hash(movie) }
    let(:attributes_to_serialize) { MovieSerializer.attributes_to_serialize }

    context 'when attribute without block' do
      it 'returns correct hash' do
        expect(attributes_hash.keys).to eq MovieSerializer.attributes_to_serialize.keys
        attributes_to_serialize.each do |key, method_name|
          expect(attributes_hash[key]).to eq movie.send(method_name)
        end
      end
    end

    context 'when attribute without block' do
      before do
        MovieSerializer.attribute :name_with_test do |object|
          'test ' + object.name
        end
      end

      it 'returns correct hash' do
        expect(attributes_hash.keys).to eq MovieSerializer.attributes_to_serialize.keys
        expect(attributes_hash[:name]).to eq movie.name
        expect(attributes_hash[:release_year]).to eq movie.release_year
        expect(attributes_hash[:name_with_test]).to eq 'test ' + movie.name
      end
    end
  end

  describe '#self.relationships_hash' do
    subject(:relationships_hash) { MovieSerializer.relationships_hash(movie) }

    context 'when relationship is empty' do
      before do
        movie.actor_ids = []
        movie.owner_id = nil
        movie.movie_type_id = nil
      end

      it 'returns the correct empty result' do
        expect(relationships_hash[:actors][:data]).to be_empty
        expect(relationships_hash[:owner][:data]).to be_nil
        expect(relationships_hash[:movie_type][:data]).to be_nil
      end
    end

    context 'when relationship is not empty' do
      it 'returns the correct results' do
        expect(relationships_hash[:actors][:data]).to eq [{ id: '1', type: :actor }, { id: '2', type: :actor }, { id: '3', type: :actor }]
        expect(relationships_hash[:owner][:data]).to eq({ id: '3', type: :user })
        expect(relationships_hash[:movie_type][:data]).to eq({ id: '1', type: :movie_type })
      end
    end
  end

  describe '#self.record_hash' do
    subject(:record_hash) { MovieSerializer.record_hash(movie) }

    it 'returns correct hash' do
      expect(record_hash[:id]).to eq movie.id.to_s
      expect(record_hash[:type]).to eq MovieSerializer.record_type
      expect(record_hash).to have_key(:attributes)
      expect(record_hash).to have_key(:relationships)
    end
  end

  describe '#self.id_from_record' do
    subject { MovieSerializer.id_from_record(record) }

    context 'when record_id is defined' do
      let(:record) { movie }

      before do
        MovieSerializer.set_id :owner_id
      end

      after do
        MovieSerializer.set_id nil
      end

      it 'returns owner_id' do
        is_expected.to eq 3
      end
    end

    context 'when record_id is not defined' do
      context 'when record responds with id method' do
        let(:record) do
          klass = Struct.new(:id)
          klass.new(1)
        end

        it 'returns id' do
          is_expected.to eq 1
        end
      end

      context 'when record does not respond with id method' do
        let(:record) do
          klass = Struct.new(:name)
          klass.new('John')
        end

        it 'raises MandatoryField error' do
          expect{ subject }.to raise_error FastJsonapi::MandatoryField
        end
      end
    end
  end

  describe '#self.get_included_records' do
    it 'serializes known included records only once' do
      includes_list = [:actors]
      known_included_objects = {}
      included_records = []
      [movie, movie].each do |record|
        included_records.concat MovieSerializer.send(:get_included_records, record, includes_list, known_included_objects)
      end
      expect(included_records.size).to eq 3
    end
  end
end
