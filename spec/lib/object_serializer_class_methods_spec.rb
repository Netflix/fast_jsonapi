require 'spec_helper'

describe FastJsonapi::ObjectSerializer do

  include_context 'movie class'

  describe '#has_many' do
    subject(:relationship) { serializer.relationships_to_serialize[:roles] }

    before do
      serializer.has_many *children
    end

    after do
      serializer.relationships_to_serialize = {}
    end

    context 'with namespace' do
      let(:serializer) { AppName::V1::MovieSerializer }
      let(:children) { [:roles] }

      context 'with overrides' do
        let(:children) { [:roles, id_method_name: :roles_only_ids, record_type: :super_role] }

        it_behaves_like 'returning correct relationship hash', :'AppName::V1::RoleSerializer', :roles_only_ids, :super_role
      end

      context 'without overrides' do
        let(:children) { [:roles] }

        it_behaves_like 'returning correct relationship hash', :'AppName::V1::RoleSerializer', :role_ids, :role
      end
    end

    context 'without namespace' do
      let(:serializer) { MovieSerializer }

      context 'with overrides' do
        let(:children) { [:roles, id_method_name: :roles_only_ids, record_type: :super_role] }

        it_behaves_like 'returning correct relationship hash', :'RoleSerializer', :roles_only_ids, :super_role
      end

      context 'without overrides' do
        let(:children) { [:roles] }

        it_behaves_like 'returning correct relationship hash', :'RoleSerializer', :role_ids, :role
      end
    end
  end

  describe '#belongs_to' do
    subject(:relationship) { MovieSerializer.relationships_to_serialize[:area] }

    before do
      MovieSerializer.belongs_to *parent
    end

    after do
      MovieSerializer.relationships_to_serialize = {}
    end

    context 'with overrides' do
      let(:parent) { [:area, id_method_name: :blah_id, record_type: :awesome_area, serializer: :my_area] }

      it_behaves_like 'returning correct relationship hash', :'MyAreaSerializer', :blah_id, :awesome_area
    end

    context 'without overrides' do
      let(:parent) { [:area] }

      it_behaves_like 'returning correct relationship hash', :'AreaSerializer', :area_id, :area
    end
  end

  describe '#has_one' do
    subject(:relationship) { MovieSerializer.relationships_to_serialize[:area] }

    before do
      MovieSerializer.has_one *partner
    end

    after do
      MovieSerializer.relationships_to_serialize = {}
    end

    context 'with overrides' do
      let(:partner) { [:area, id_method_name: :blah_id, record_type: :awesome_area, serializer: :my_area] }

      it_behaves_like 'returning correct relationship hash', :'MyAreaSerializer', :blah_id, :awesome_area
    end

    context 'without overrides' do
      let(:partner) { [:area] }

      it_behaves_like 'returning correct relationship hash', :'AreaSerializer', :area_id, :area
    end
  end

  describe '#set_id' do
    subject(:serializable_hash) { MovieSerializer.new(resource).serializable_hash }

    before do
      MovieSerializer.set_id :owner_id
    end

    after do
      MovieSerializer.set_id nil
    end

    context 'when one record is given' do
      let(:resource) { movie }

      it 'returns correct hash which id equals owner_id' do
        expect(serializable_hash[:data][:id].to_i).to eq movie.owner_id
      end
    end

    context 'when an array of records is given' do
      let(:resource) { [movie, movie] }

      it 'returns correct hash which id equals owner_id' do
        expect(serializable_hash[:data][0][:id].to_i).to eq movie.owner_id
        expect(serializable_hash[:data][1][:id].to_i).to eq movie.owner_id
      end
    end
  end

  describe '#use_hyphen' do
    subject { MovieSerializer.use_hyphen }

    after do
      MovieSerializer.transform_method = nil
    end

    it 'sets the correct transform_method when use_hyphen is used' do
      warning_message = "DEPRECATION WARNING: use_hyphen is deprecated and will be removed from fast_jsonapi 2.0 use (set_key_transform :dash) instead\n"
      expect { subject }.to output(warning_message).to_stderr
      expect(MovieSerializer.instance_variable_get(:@transform_method)).to eq :dasherize
    end
  end

  describe '#attribute' do
    subject(:serializable_hash) { MovieSerializer.new(movie).serializable_hash }

     after do
       MovieSerializer.attributes_to_serialize = {}
     end

    context 'with block' do
      before do
        movie.release_year = 2008
        MovieSerializer.attribute :title_with_year do |record|
          "#{record.name} (#{record.release_year})"
        end
      end

      it 'returns correct hash when serializable_hash is called' do
        expect(serializable_hash[:data][:attributes][:name]).to eq movie.name
        expect(serializable_hash[:data][:attributes][:title_with_year]).to eq "#{movie.name} (#{movie.release_year})"
      end
    end
  end

  describe '#link' do
    subject(:serializable_hash) { MovieSerializer.new(movie).serializable_hash }

    after do
      MovieSerializer.data_links = {}
      ActorSerializer.data_links = {}
    end

    context 'with block calling instance method on serializer' do
      before do
        MovieSerializer.link(:self) do |movie_object|
          movie_url(movie_object)
        end
      end
      let(:url) { "http://movies.com/#{movie.id}" }

      it 'returns correct hash when serializable_hash is called' do
        expect(serializable_hash[:data][:links][:self]).to eq url
      end
    end

    context 'with block and param' do
      before do
        MovieSerializer.link(:public_url) do |movie_object|
          "http://movies.com/#{movie_object.id}"
        end
      end
      let(:url) { "http://movies.com/#{movie.id}" }

      it 'returns correct hash when serializable_hash is called' do
        expect(serializable_hash[:data][:links][:public_url]).to eq url
      end
    end

    context 'with method' do
      before do
        MovieSerializer.link(:object_id, :id)
      end

      it 'returns correct hash when serializable_hash is called' do
        expect(serializable_hash[:data][:links][:object_id]).to eq movie.id
      end
    end
  end
end
